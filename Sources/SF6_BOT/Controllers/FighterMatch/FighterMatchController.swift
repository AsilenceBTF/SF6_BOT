//
//  FighterMatch.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/30.
//
import Vapor
import Fluent

final class FighterMatchController {
    public func wantFight(req: Request, content: any Content, params: [String]) async throws -> String {
        // 1. 确保content类型为OneBotMessage
        guard let requestMsg = content as? OneBotMessage else {
            return "WantFight Error:Trans to OneBotMessage Faild"
        }
        
        // 2. 获取群ID
        guard let groupId = requestMsg.group_id else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取群信息")
            return "无法获取群信息"
        }
        
        // 新逻辑：如果参数只有一个，且为<300的数字，则调用join方法
        if params.count == 1, let matchId = Int(params[0]), matchId < 300 {
            return try await joinMatch(req: req, content: content, params: params)
        }
        
        // 3. 从OneBotMessage中提取用户信息
        guard let userId = requestMsg.sender?.user_id, let userNickname = requestMsg.sender?.nickname else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取用户信息")
            return "无法获取用户信息"
        }
        
        // 4. 更新或创建QQUserModel
        if let existingUser = try await QQUserModel.query(on: req.db)
            .filter(\.$userId == userId)
            .first() {
            // 用户已存在，更新昵称（如果有变化）
            if existingUser.nikeName != userNickname {
                existingUser.nikeName = userNickname
                try await existingUser.save(on: req.db)
            }
        } else {
            // 用户不存在，创建新记录
            let newUser = QQUserModel()
            newUser.userId = userId
            newUser.nikeName = userNickname
            try await newUser.save(on: req.db)
        }
        
        // 5. 解析params参数，按照角色、分数、备注的顺序处理
        var characterId: Int?
        var score: Int?
        var masterScore: Int?
        var notes: String?
        
        // 解析角色信息（第一个参数）
        if params.count > 0 {
            let characterName = params[0]
            if let character = try await CharacterModel.getModelFromName(db: req.db, character: characterName) {
                characterId = character.id
            } else {
                // 角色未找到，将第一个参数作为备注
                notes = characterName
            }
        }
        
        // 解析分数信息（第二个参数）
        if params.count > 1 {
            let scoreParam = params[1]
            if scoreParam.lowercased().hasPrefix("m") {
                // 大师段位格式 mxxx
                masterScore = Int(scoreParam.dropFirst())
            } else if let scoreValue = Int(scoreParam) {
                // 普通分数
                score = scoreValue
            } else {
                // 不是有效的分数格式，作为备注处理
                if notes == nil {
                    notes = scoreParam
                } else {
                    notes! += " " + scoreParam
                }
            }
        }
        
        // 解析备注信息（第三个及之后的参数）
        if params.count > 2 {
            let notesParam = params[2...].joined(separator: " ")
            if notes == nil {
                notes = notesParam
            } else {
                notes! += " " + notesParam
            }
        }
        
        // 6. 检查用户是否已有待战记录（在当前群）
        let match: FighterMatchesModel
        if let existingMatch = try await FighterMatchesModel.query(on: req.db)
            .filter(\.$firstUID == userId)
            .filter(\.$groupId == groupId)
            .filter(\.$matchStatus == .pending)
            .first() {
            // 已有待战记录，更新该记录
            match = existingMatch
            match.characterID = characterId
            match.notes = notes
            match.score = score
            match.masterScore = masterScore
            // 更新时间
        } else {
            // 没有待战记录，创建新记录
            match = FighterMatchesModel()
            match.firstUID = userId
            match.groupId = groupId
            match.characterID = characterId
            match.notes = notes
            match.score = score
            match.masterScore = masterScore
            match.matchStatus = .pending
            
            // 7. 分配一个合适的ID，避免ID过大
            // 查找最小的可用ID（从1开始）
            match.id = try await findAvailableSmallId(req: req)
        }
        
        try await match.save(on: req.db)
        
        // 8. 构建响应消息
        var responseMsg = "🎮 约战成功！\n"
        
        // 添加用户信息
        responseMsg += "玩家: \(userNickname)"
        
        // 添加角色信息（如果有）
        if let characterId = characterId, 
           let character = try await CharacterModel.query(on: req.db)
                .filter(\.$id == characterId)
                .first() {
            responseMsg += " 使用角色: \(character.chineseName)"
        }
        
        // 添加分数信息（如果有）
        if let score = score {
            responseMsg += "\n格斗积分: \(score)"
        }
        if let masterScore = masterScore {
            responseMsg += "\n大师段位: m\(masterScore)"
        }
        
        // 添加备注信息（如果有）
        if let notes = notes {
            responseMsg += "\n备注: \(notes)"
        }
        
        responseMsg += "\n\n📝 发送 /list 查看待战列表\n"
        responseMsg += "📝 发送 /cancel 取消约战"
        
        // 9. 发送响应消息
        BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
        
        return responseMsg
    }
    
    /// 查找最小的可用ID（从1开始）
    private func findAvailableSmallId(req: Request) async throws -> Int {
        // 查询所有已存在的匹配记录
        let allMatches = try await FighterMatchesModel.query(on: req.db).all()
        
        // 收集所有已使用的ID
        let usedIds = Set(allMatches.compactMap { $0.id })
        
        // 从1开始查找最小的未使用ID
        for i in 1...usedIds.count + 10 { // 检查当前数量+10的范围
            if !usedIds.contains(i) {
                return i
            }
        }
        
        // 如果上述范围都没有找到（理论上不应该发生），则返回当前最大ID+1
        if let maxId = usedIds.max() {
            return maxId + 1
        }
        
        // 如果没有任何记录，返回1
        return 1
    }
    
    func cancelMatch(req: Request, content: any Content) async throws -> String {
        // 1. 确保content类型为OneBotMessage
        guard let requestMsg = content as? OneBotMessage else {
            return "CancelMatch Error:Trans to OneBotMessage Faild"
        }
        
        // 2. 获取群ID
        guard let groupId = requestMsg.group_id else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取群信息")
            return "无法获取群信息"
        }
        
        // 3. 从OneBotMessage中提取用户信息
        guard let userId = requestMsg.sender?.user_id else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取用户信息")
            return "无法获取用户信息"
        }
        
        // 4. 查询用户的待战记录（在当前群）
        if let pendingMatch = try await FighterMatchesModel.query(on: req.db)
            .filter(\.$firstUID == userId)
            .filter(\.$groupId == groupId)
            .filter(\.$matchStatus == .pending)
            .first() {
            
            // 5. 找到待战记录，更新状态为已完成（或取消）
            pendingMatch.matchStatus = .completed
            try await pendingMatch.save(on: req.db)
            
            // 6. 构建响应消息
            let responseMsg = "✖️ 已成功取消约战！\n" +
                              "📝 发送 /fight 角色名 分数 备注 重新约战\n" +
                              "📝 发送 /list 查看待战列表"
            
            // 7. 发送响应消息
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
            
            return responseMsg
        } else {
            // 没有找到待战记录
            let responseMsg = "❌ 未找到您的待战记录！\n" +
                              "📝 发送 /fight 角色名 分数 备注 发起约战\n" +
                              "📝 发送 /list 查看待战列表"
            
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
            
            return responseMsg
        }
    }
    
    func joinMatch(req: Request, content: any Content, params: [String]) async throws -> String {
        // 1. 确保content类型为OneBotMessage
        guard let requestMsg = content as? OneBotMessage else {
            return "JoinMatch Error:Trans to OneBotMessage Faild"
        }
        
        // 2. 获取群ID
        guard let groupId = requestMsg.group_id else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取群信息")
            return "无法获取群信息"
        }
        
        // 3. 从OneBotMessage中提取用户信息
        guard let userId = requestMsg.sender?.user_id, let userNickname = requestMsg.sender?.nickname else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取用户信息")
            return "无法获取用户信息"
        }
        
        // 4. 从params中获取match的Id
        guard params.count > 0, let matchId = Int(params[0]) else {
            let responseMsg = "❌ 命令格式错误！请使用：/join 序号\n" +
                              "📝 发送 /list 查看待战列表"
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
            return responseMsg
        }
        
        // 5. 查询对应的待战记录（在当前群）
        guard let selectedMatch = try await FighterMatchesModel.query(on: req.db)
            .filter(\.$id == matchId)
            .filter(\.$groupId == groupId)
            .filter(\.$matchStatus == .pending)
            .first() else {
            let responseMsg = "❌ 未找到对应序号的待战记录！\n" +
                              "📝 发送 /list 查看最新待战列表"
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
            return responseMsg
        }
        
        // 6. 检查是否是加入自己的约战
        if selectedMatch.firstUID == userId {
            let responseMsg = "❌ 不能加入自己发起的约战！\n" +
                              "📝 发送 /cancel 取消约战\n" +
                              "📝 发送 /list 查看其他待战列表"
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
            return responseMsg
        }
        
        // 7. 更新约战记录
        selectedMatch.secondUID = userId
        selectedMatch.matchStatus = .completed
        try await selectedMatch.save(on: req.db)
        
        // 8. 构建响应消息
        var responseMsg = "成功加入约战！\(String.napCatCQString(userId: selectedMatch.firstUID)) \(String.napCatCQString(userId: userId))"
        
        // 9. 发送响应消息
        BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: responseMsg)
        
        return responseMsg
    }
    
    /// 获取待战列表
    func matchList(req: Request, content: any Content) async throws -> String {
        // 1. 确保content类型为OneBotMessage
        guard let requestMsg = content as? OneBotMessage else {
            return "MatchList Error:Trans to OneBotMessage Faild"
        }
        
        // 2. 获取群ID
        guard let groupId = requestMsg.group_id else {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "无法获取群信息")
            return "无法获取群信息"
        }
        
        // 查询当前群所有待战状态的匹配记录
        let pendingMatches = try await FighterMatchesModel.query(on: req.db)
            .filter(\.$groupId == groupId)
            .filter(\.$matchStatus == .pending)
            .all()
        
        if pendingMatches.isEmpty {
            BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: "当前暂无待战玩家。")
            return "当前暂无待战玩家。"
        }
        
        var result = "🎮 待战列表\n"
        
        // 遍历所有待战记录，添加关键信息（更紧凑的格式）
        for match in pendingMatches {
            // 获取发起者信息
            var userInfo = ""
            if let user = try await QQUserModel.query(on: req.db)
                .filter(\.$userId == match.firstUID)
                .first() {
                userInfo = user.nikeName
            } else {
                userInfo = "[QQ:\(match.firstUID)]"
            }
            
            // 构建单条记录的信息，使用更紧凑的格式
            var recordInfo = "\(match.id!). \(userInfo)"
            
            // 添加角色信息（如果有）
            if let characterId = match.characterID, 
               let character = try await CharacterModel.query(on: req.db)
                    .filter(\.$id == characterId)
                    .first() {
                recordInfo += " [\(character.chineseName)]"
            }
            
            // 添加分数信息（精简显示）
            if let score = match.score {
                recordInfo += " \(score)分"
            }
            if let masterScore = match.masterScore {
                recordInfo += " m\(masterScore)"
            }
            
            // 添加备注信息（只显示前10个字符）
            if let notes = match.notes, !notes.isEmpty {
                let shortNotes = notes.count > 10 ? String(notes.prefix(10)) + "..." : notes
                recordInfo += " (\(shortNotes))"
            }
            
            // 每条记录占一行
            result += recordInfo + "\n"
        }
        
        // 添加操作提示
        result += "📝 发送 /join 序号 加入对战\n"
        result += "📝 发送 /fight 角色名 分数 备注 发起约战"
        
        // 发送响应消息
        BotOpenAPIManager.defaultAPI.sendMessage(content: content, msg: result)
        
        return result
    }
}
