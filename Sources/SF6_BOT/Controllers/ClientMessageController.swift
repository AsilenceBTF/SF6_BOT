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
    case frameDataQuery = "帧数查询"
    case wantFight = "约战"
    case chainCancelQuery = "可绿冲取消"
    case saCancelQuery = "可sa取消"
    case menuQuery = "菜单"
    case none = "none"
    
    static func fromString(_ string: String) -> CommandType {
        return CommandType(rawValue: string) ?? CommandType.none
    }
    
    static var menuString: String {
        get {
            var desc = "\n1./帧数查询 角色名 指令或拳脚\n"
            desc += "2./约战(测试中)\n"
            desc += "3./可绿冲取消 角色名"
            desc += "4./可SA取消 角色名"
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
    
    public func handleDispatchMessage(req: Request) async throws -> Response {
        let dispatchResult = try req.content.decode(QQDispatchMsgResult.self)
        
        let (commondType, params) = String.parseCommandType(content: dispatchResult.d?.content)
        var returnMsg: String = ""
        
        switch commondType {
            
        case .frameDataQuery:
            returnMsg = try await frameDataQuery.handle(req: req, qqMSg: dispatchResult, params: params)
            
        case .chainCancelQuery:
            returnMsg = try await chainCancelQuery.handle(req: req, qqMSg: dispatchResult, params: params)
            
        case .saCancelQuery:
            returnMsg = try await saCancelQuery.handle(req: req, qqMSg: dispatchResult, params: params)
            
        case .wantFight:
            returnMsg = try await figherMatch.handle(req: req, qqMSg: dispatchResult, params: params)
            
        case .menuQuery:
            _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: dispatchResult, msg: CommandType.menuString)
            returnMsg = CommandType.menuString
            
        case .none:
            _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: dispatchResult, msg: "指令错误，使用'/菜单'查看帮助")
            returnMsg = "指令错误，使用'/菜单'查看帮助"
        }
        
        let response = Response(status: .ok)
        try response.content.encode(["result":returnMsg], as: .json)
        return response
    }
   
}

extension String {
    func pinyin() -> String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        var result = mutableString as String
        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }
    
    // 解析指令
    static func parseCommandType(content: String?) -> (CommandType, [String]) {
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
