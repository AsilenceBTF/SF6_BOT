//
//  ClientMessageController.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/27.
//
import Vapor
import Fluent

// 定义指令类型的枚举
enum CommandType: String {
    case frameDataQuery = "/帧数"
    case wantFight = "/fight"
    case joinFight = "/join"
    case cancelFight = "/cancel"
    case waitFightList = "/list"
    case chainCancelQuery = "/绿冲取消"
    case saCancelQuery = "/sa取消"
    case menuQuery = "/菜单"
    case none = "none"
    case ignore = "ignore"
    
    // 优化命令匹配逻辑，支持模糊匹配
    static func fromString(_ string: String) -> CommandType {
        // 去除字符串前后空格并转为小写
        var normalizedString = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 如果没有前缀"/"，直接返回.none
        if !normalizedString.hasPrefix("/") {
            return .none
        }
        
        normalizedString = String(normalizedString.dropFirst())
        
        // 支持命令别名和模糊匹配
        switch normalizedString {
        case "帧数", "帧数查询", "查帧数":
            return .frameDataQuery
        case "约战", "fight", "匹配", "wantFight":
            return .wantFight
        case "加入", "join", "参战":
            return .joinFight
        case "取消", "cancel", "取消约战":
            return .cancelFight
        case "待战", "matchlist", "list":
            return .waitFightList
        case "绿冲", "绿冲取消查询", "绿冲取消表", "绿冲取消":
            return .chainCancelQuery
        case "sa取消", "sa取消查询", "sa取消表":
            return .saCancelQuery
        case "菜单", "帮助", "help", "菜单查询":
            return .menuQuery
        default:
            return .none
        }
    }
    
    static var menuString: String {
        get {
            var desc = "1./帧数 角色名 指令或拳脚\n"
            desc += "2.约战:\n"
            desc += "   2.1 /fight 角色名 分数 备注\n"
            desc += "   2.2 /join 序号\n"
            desc += "   2.3 /cancel(取消约战)\n"
            desc += "   2.4 /list(待战列表)\n"
            desc += "3./绿冲取消 角色名\n"
            desc += "4./SA取消 角色名\n"
            desc += "5./菜单(显示帮助菜单)"
            return desc
        }
    }
}

final class ClientMessageController {
    private let frameDataQuery: any BaseQueryProtocol = FrameDataQueryController()
    private let chainCancelQuery: any BaseQueryProtocol = ChainCancelQueryController()
    private let saCancelQuery: any BaseQueryProtocol = SACancelQueryController()
    private let figherMatch: FighterMatchController = FighterMatchController()
    private let openAPI: any BotOpenAPI = QQBotOpenAPI.shared
    
    // user_id白名单
    private let userWhiteList: [Int] = 
        (Environment.get("ONEBOT_USER_WHITE_LIST") ?? "")
        .split(separator: ",")
        .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    
    // group_id白名单
    private let groupWhiteList: [Int] = 
        (Environment.get("ONEBOT_GROUP_WHITE_LIST") ?? "")
        .split(separator: ",")
        .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    
    private let napcatUid = Int((Environment.get("ONEBOT_BOT_USER_ID") ?? "")) ?? 0
    
    public func handleQQDispatchMessage(req: Request) async throws -> Response {
        let dispatchResult = try req.content.decode(QQDispatchMsgResult.self)
        
        let (commondType, params) = String.parseQQCommandType(content: dispatchResult.d?.content)
        let returnMsg = try await handleDispatchCommond(req: req, content: dispatchResult, commondType: commondType, params: params)
        
        let response = Response(status: .ok)
        try response.content.encode(["result":returnMsg], as: .json)
        return response
    }
    
    public func handleNapCatDispatchMessage(req: Request) async throws -> Response {
        let dispatchResult = try req.content.decode(OneBotMessage.self)
        
        if (dispatchResult.user_id == napcatUid) {
            return Response(status: .accepted)
        }
        
//        // 白名单之外的用户
//        guard (userWhiteList.contains { $0 == dispatchResult.user_id } ||
//               groupWhiteList.contains { $0 == dispatchResult.group_id }) else {
//            // 不在白名单中的处理
//            return Response(status: .accepted)
//        }

        let (commondType, params) = String.parseNapCatCommandType(content: dispatchResult.message)
        
        let returnMsg = try await handleDispatchCommond(req: req, content: dispatchResult, commondType: commondType, params: params)
        
        let response = Response(status: .ok)
        try response.content.encode(["result":returnMsg], as: .json)
        return response
    }
    
    public func handleDispatchCommond(req: Request, content: any Content, commondType: CommandType, params: [String]) async throws -> String {
        var returnMsg: String = ""
        switch commondType {
        case .wantFight:
            returnMsg = try await figherMatch.wantFight(req: req, content: content, params: params)
            
        case .cancelFight:
            returnMsg = try await figherMatch.cancelMatch(req: req, content: content)
            
        case .joinFight:
            returnMsg = try await figherMatch.joinMatch(req: req, content: content, params: params)
            
        case .waitFightList:
            returnMsg = try await figherMatch.matchList(req: req, content: content)
            
        case .frameDataQuery:
            returnMsg = try await frameDataQuery.handle(req: req, content: content, params: params)
            
        case .chainCancelQuery:
            returnMsg = try await chainCancelQuery.handle(req: req, content: content, params: params)
            
        case .saCancelQuery:
            returnMsg = try await saCancelQuery.handle(req: req, content: content, params: params)
            
        case .menuQuery:
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: CommandType.menuString)
            returnMsg = CommandType.menuString
            
        case .none:
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "指令错误，使用'菜单'查看帮助")
            returnMsg = "指令错误，使用'菜单'查看帮助"
            
        case .ignore:
            break
        }
        return returnMsg
    }
}

extension String {
    static func napCatCQString(userId: Int) -> String {
        return "[CQ:at,qq=\(userId)]"
    }
    
    // 解析NapCat指令
    static func parseNapCatCommandType(content: String?) -> (CommandType, [String]) {
        // 检查内容是否为空
        guard let content = content, !content.isEmpty else {
            return (.ignore, [])
        }
        
        let botUID: Int = Int((Environment.get("ONEBOT_BOT_USER_ID") ?? "")) ?? 0
        if (botUID == 0) {
            return (.ignore, [])
        }
        
        let atCommond = napCatCQString(userId: botUID)
        
        // 预处理内容
        var realContent = content
        let containsAt = content.contains(atCommond)
        
        // 如果包含@机器人标记，移除它
        if containsAt {
            realContent = content.replacingOccurrences(of: atCommond, with: "")
        } else {
            if !content.hasPrefix("/") {
                return (.ignore, [])
            }
        }
        
        // 预处理内容
        let lowercaseContent = realContent.lowercased()
        let trimmedContent = lowercaseContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 按照空格分割消息内容
        let components = trimmedContent.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty } // 过滤掉空字符串
        
        if components.count >= 1 {
            var firstComponent = components[0]
            // 如果@了机器人但命令没有加/前缀，自动补上
            if containsAt && !firstComponent.hasPrefix("/") {
                firstComponent = "/" + firstComponent
            }
            
            let commandType = CommandType.fromString(firstComponent)
            let params = components.dropFirst()
            return (commandType, Array(params))
        }
        
        // 如果没有空格分隔的参数，尝试将整个内容作为命令
        var processedContent = trimmedContent
        if containsAt && !trimmedContent.hasPrefix("/") {
            processedContent = "/" + trimmedContent
        }
        
        return (CommandType.fromString(processedContent), [])
    }
    
    // 解析QQ指令
    static func parseQQCommandType(content: String?) -> (CommandType, [String]) {
        // 检查内容是否为空
        guard let content = content, !content.isEmpty else {
            return (.none, [])
        }
        
        // 预处理内容
        let lowercaseContent = content.lowercased()
        let trimmedContent = lowercaseContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否包含@机器人标记
        let botUID: Int = Int((Environment.get("ONEBOT_BOT_USER_ID") ?? "")) ?? 0
        let atCommond = napCatCQString(userId: botUID)
        let containsAt = content.contains(atCommond)
        
        // 移除@机器人标记（如果存在）
        var processedContent = content
        if containsAt {
            processedContent = content.replacingOccurrences(of: atCommond, with: "")
            processedContent = processedContent.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        } else {
            processedContent = trimmedContent
        }
        
        // 无论是否有前缀斜杠，都尝试进行解析
        let messageContent: String
        if processedContent.hasPrefix("/") {
            messageContent = processedContent
        } else {
            // 如果@了机器人但命令没有加/前缀，自动补上
            if containsAt {
                messageContent = "/" + processedContent
            } else {
                // 对于直接命令，保持原有逻辑
                messageContent = "/" + processedContent
            }
        }
        
        // 按照空格分割消息内容
        let components = messageContent.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty } // 过滤掉空字符串
        
        if components.count >= 1 {
            let commandType = CommandType.fromString(components[0])
            let params = components.dropFirst()
            return (commandType, Array(params))
        }
        
        // 如果没有空格分隔的参数，尝试将整个内容作为命令
        return (CommandType.fromString(messageContent), [])
    }
}
