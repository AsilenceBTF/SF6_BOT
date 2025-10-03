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
    case frameDataQuery = "帧数"
    case wantFight = "约战"
    case waitFightMenu = "待战列表"
    case chainCancelQuery = "绿冲取消"
    case saCancelQuery = "sa取消"
    case menuQuery = "菜单"
    case none = "none"
    
    static func fromString(_ string: String) -> CommandType {
        return CommandType(rawValue: string) ?? CommandType.none
    }
    
    static var menuString: String {
        get {
            var desc = "\n1.帧数 角色名 指令或拳脚\n"
            desc += "2.约战\n"
            desc += "3.待战\n"
            desc += "4.绿冲取消 角色名\n"
            desc += "5.SA取消 角色名\n"
            desc += "6.菜单(显示帮助菜单)"
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
        
        // 白名单之外的用户
        guard (userWhiteList.contains { $0 == dispatchResult.user_id } ||
               groupWhiteList.contains { $0 == dispatchResult.group_id }) else {
            // 不在白名单中的处理
            return Response(status: .accepted)
        }

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
            returnMsg = try await figherMatch.handle(req: req, content: content, params: params)
            
        case .waitFightMenu:
            returnMsg = ""
            
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
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "指令错误，使用'/菜单'查看帮助")
            returnMsg = "指令错误，使用'/菜单'查看帮助"
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
        let botUID: Int = Int((Environment.get("ONEBOT_BOT_USER_ID") ?? "")) ?? 0
        let atCommond = napCatCQString(userId: botUID)
        guard (content?.contains(atCommond) ?? false) else {
            return (CommandType.none, [])
        }
    
        // 去掉at前缀
        let realContent = content?.replacingOccurrences(of: atCommond, with: "")
    
        // 小写
        let lowercaseContent = realContent?.lowercased()
        let trimmedContent = lowercaseContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // 按照空格分割消息内容
        let components = trimmedContent.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty } // 过滤掉空字符串
        
        if components.count >= 1 {
            let commandType = CommandType.fromString(components[0])
            let params = components.dropFirst()
            return (commandType, Array(params))
        }
        
        return (CommandType.none, [])
    }
    
    // 解析QQ指令
    static func parseQQCommandType(content: String?) -> (CommandType, [String]) {
        // 小写
        let lowercaseContent = content?.lowercased()
        let trimmedContent = lowercaseContent?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard (trimmedContent?.hasPrefix("/") ?? false) else {
            return (CommandType.none, [])
        }
        
        let messageWithoutSlash = String(trimmedContent?.dropFirst() ?? "")
        // 按照空格分割消息内容
        let components = messageWithoutSlash.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty } // 过滤掉空字符串
        
        if components.count >= 1 {
            let commandType = CommandType.fromString(components[0])
            let params = components.dropFirst()
            return (commandType, Array(params))
        }
        
        return (CommandType.none, [])
    }
}
