//
//  SACancelQueryController.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/30.
//
import Fluent
import Vapor

final class SACancelQueryController : BaseQueryProtocol {
    struct SAQueryMessage {
        var character: CharacterModel?
        var moves: [MoveModel]?
        var errorMessage: String?
    }
    
    func handle(req: Request, qqMSg: QQDispatchMsgResult, params: [String]) async throws -> String {
        let queryResult = await query(req: req, params: params)
        if let errorMsg = queryResult.errorMessage {
            _ = await BotOpenAPI.shared.sendMessage(dispathRequest: qqMSg, msg: errorMsg)
            return errorMsg
        } else {
            var desc = ""
            if let moves = queryResult.moves, moves.count > 0 {
                desc += "\(queryResult.character?.chineseName ?? "")可以SA取消:\n"
                desc += moves.compactMap { $0.input }.joined(separator: ",")
            } else {
                desc = "\(queryResult.character?.chineseName ?? "")没有可以SA取消的拳脚"
            }
            _ = await BotOpenAPI.shared.sendMessage(dispathRequest: qqMSg, msg: desc)
            return desc
        }
    }
    
    func query(req: Request, params: [String]) async -> SAQueryMessage {
        var queryMsg = SAQueryMessage()
        if (params.count >= 1) {
            do {
                let typeCharacterName = params[0]
                if let character = try await CharacterModel.getModelFromName(db: req.db, character: typeCharacterName) {
                    queryMsg.character = character
                    var moves: [MoveModel] = []
                    
                    let SA1 = try await MoveModel.query(on: req.db)
                        .filter(\MoveModel.$characterId == character.id)
                        .filter(\MoveModel.$cancel == "SA")
                        .all()
                    let SA2 = try await MoveModel.query(on: req.db)
                        .filter(\MoveModel.$characterId == character.id)
                        .filter(\MoveModel.$cancel == "SA2")
                        .all()
                    let SA3 = try await MoveModel.query(on: req.db)
                        .filter(\MoveModel.$characterId == character.id)
                        .filter(\MoveModel.$cancel == "SA3")
                        .all()
                    moves.append(contentsOf: SA1)
                    moves.append(contentsOf: SA2)
                    moves.append(contentsOf: SA3)
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
