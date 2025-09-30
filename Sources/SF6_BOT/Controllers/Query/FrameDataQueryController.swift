//
//  FrameDataQueryController.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/30.
//
import Vapor

final class FrameDataQueryController : BaseQueryProtocol {
    struct FrameQueryMessage {
        var character: CharacterModel?
        var move: MoveModel?
        var errorMessage: String?
    }
    
    func handle(req: Request, qqMSg: QQDispatchMsgResult, params: [String]) async throws -> String {
        let queryResult = await query(req: req, params: params)
        if let errorMsg = queryResult.errorMessage {
            _ = await BotOpenAPI.shared.sendMessage(dispathRequest: qqMSg, msg: errorMsg)
            return errorMsg
        } else {
            var desc = "\n角色:\(queryResult.character?.chineseName ?? "")"
            desc += " " + (queryResult.move?.description ?? "")
            _ = await BotOpenAPI.shared.sendMessage(dispathRequest: qqMSg, msg: desc)
            return desc
        }
    }
    
    private func query(req: Request, params: [String]) async -> FrameQueryMessage {
        var queryMsg = FrameQueryMessage()
        if (params.count >= 2) {
            do {
                let typeCharacterName = params[0]
                let typeInputName = params[1]
                if let character = try await CharacterModel.getModelFromName(db: req.db, character: typeCharacterName) {
                    if let move = try await MoveModel.getModelBySearchTerm(db: req.db, character: character, searchTerm: typeInputName) {
                        queryMsg.character = character
                        queryMsg.move = move
                    } else {
                        queryMsg.errorMessage = "未收录招式:\(typeInputName)"
                    }
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
