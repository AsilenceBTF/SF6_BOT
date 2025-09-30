//
//  ChainCancelQueryController.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/30.
//
import Fluent
import Vapor

final class ChainCancelQueryController : BaseQueryProtocol {
    struct ChainQueryMessage {
        var character: CharacterModel?
        var moves: [MoveModel]?
        var errorMessage: String?
    }
    
    func handle(req: Request, qqMSg: QQDispatchMsgResult, params: [String]) async throws -> String {
        let queryResult = await query(req: req, params: params)
        if let errorMsg = queryResult.errorMessage {
            _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: qqMSg, msg: errorMsg)
            return errorMsg
        } else {
            var desc = ""
            if let moves = queryResult.moves, moves.count > 0 {
                desc += "\(queryResult.character?.chineseName ?? "")可以绿冲取消:\n"
                desc += moves.compactMap { $0.input }.joined(separator: ",")
            } else {
                desc = "\(queryResult.character?.chineseName ?? "")没有可以绿冲取消的拳脚"
            }
            _ = try await BotOpenAPI.shared.sendMessage(dispathRequest: qqMSg, msg: desc)
            return desc
        }
    }
    
    func query(req: Request, params: [String]) async -> ChainQueryMessage {
        var queryMsg = ChainQueryMessage()
        if (params.count >= 1) {
            do {
                let typeCharacterName = params[0]
                if let character = try await CharacterModel.getModelFromName(db: req.db, character: typeCharacterName) {
                    queryMsg.character = character
                    let moves = try await MoveModel.query(on: req.db)
                        .filter(\MoveModel.$characterId == character.id)
                        .filter(\MoveModel.$cancel == "C")
                        .all()
                    queryMsg.moves = moves
                } else {
                    queryMsg.errorMessage = "未收录角色:\(typeCharacterName)"
                }
            } catch {
                queryMsg.errorMessage = "错误指令"
            }
        } else {
            queryMsg.errorMessage = "错误指令"
        }
        return queryMsg
    }
}
