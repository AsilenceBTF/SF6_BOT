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
    case menuQuery = "菜单"
    
    static func fromString(_ string: String) -> CommandType? {
        return CommandType(rawValue: string)
    }
}

// 定义消息解析结果的结构体
struct ParsedMessage {
    let name: String?
    let commandType: CommandType?
    let character: CharacterModel?
    let move: MoveModel?
    let errorMessage: String?
}

final class ClientMessageController {
    public func handleDispatchMessage(req: Request) async throws -> Response {
        let dispatchResult = try req.content.decode(QQDispatchMsgResult.self)
        
        if let content = dispatchResult.d?.content {
            // 处理消息内容，按照空格分割并匹配指令类型、角色和招式
            let parsedResult = try await parseMessageContent(req: req, content: content)

            switch parsedResult.commandType {
            case .frameDataQuery:
                let desc = "\n角色:\(parsedResult.name ?? "")" + (parsedResult.move?.description ?? "")
                _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: dispatchResult, msg: desc)
                
            case .menuQuery:
                var desc = "\n1./帧数查询 角色名 指令或拳脚\n"
                desc += "2./约战(开发中)\n"
                desc += "3./菜单(显示帮助菜单)"
                _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: dispatchResult, msg: desc)
                
            case .none:
                if let error = parsedResult.errorMessage {
                    _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: dispatchResult, msg: error)
                    return Response(status: .accepted)
                }
            }
        }
        return Response(status: .accepted)
    }
    
    /// 解析消息内容，按照空格分割并匹配指令类型、角色和招式
    /// - Parameter content: 消息内容，格式为 "/指令类型 角色 招式"
    /// - Returns: 解析结果，包含指令类型、角色、招式和其他参数
    private func parseMessageContent(req:Request, content: String) async throws -> ParsedMessage {
        let lowercaseContent = content.lowercased()
        let trimmedContent = lowercaseContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查消息是否以斜杠开头
        guard trimmedContent.hasPrefix("/") else {
            return ParsedMessage(
                name: nil,
                commandType: nil,
                character: nil,
                move: nil,
                errorMessage: "错误指令，请参考实例输入"
            )
        }

        // 去掉开头的斜杠
        let messageWithoutSlash = String(trimmedContent.dropFirst())
        
        // 按照空格分割消息内容
        let components = messageWithoutSlash.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty } // 过滤掉空字符串
        
        // 根据分割后的部分匹配指令类型和参数
        if components.count >= 1 {
            let commandString = components[0]
            
            // 尝试将字符串转换为指令类型
            if let commandType = CommandType.fromString(commandString) {
                switch commandType {
                case .frameDataQuery:
                    // 帧数查询指令必须有两个参数（角色和招式）
                    if components.count == 3 {
                        let character = components[1]
                        let move = components[2]
                        if let cModel = try await CharacterModel.getModelFromName(req: req, character: character) {
                            if let moveM = try await MoveModel.getModelBySearchTerm(req: req, character: cModel, searchTerm: move) {
                                return ParsedMessage(name:character, commandType: commandType, character: cModel, move: moveM, errorMessage: nil)
                            }
                        }
        
                    }
                case .menuQuery:
                    return ParsedMessage(name:nil, commandType: commandType, character: nil, move: nil, errorMessage: nil)
                }
            }
        }
        return ParsedMessage(
            name: nil,
            commandType: nil,
            character: nil,
            move: nil,
            errorMessage: "错误指令，请参考实例输入"
        )
    }
}
