//
//  MoveModel.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/29.
//

import Fluent
import Vapor

final class MoveModel: @unchecked Sendable, Model {
    static let schema: String = "moves"
    
    // 唯一标识符
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    // 招式英文名称
    @Field(key: "name")
    var name: String?
    
    // 招式中文名称
    @Field(key: "zh_hans_name")
    var zhHansName: String?
    
    // 输入指令
    @Field(key: "input")
    var input: String?
    
    // 起手帧数
    @Field(key: "startup")
    var startup: String?
    
    // 有效帧数
    @Field(key: "active")
    var active: String?
    
    // 恢复帧数
    @Field(key: "recovery")
    var recovery: String?
    
    // 命中后帧数
    @Field(key: "on_hit")
    var onHit: String?
    
    // 被防御后帧数
    @Field(key: "on_block")
    var onBlock: String?
    
    // Drive Rush命中后帧数
    @Field(key: "dr_on_hit")
    var drOnHit: String?
    
    // Drive Rush被防御后帧数
    @Field(key: "dr_on_block")
    var drOnBlock: String?
    
    // 取消标记
    @Field(key: "cancel")
    var cancel: String?
    
    // 基础伤害
    @Field(key: "base_damage")
    var baseDamage: Int?
    
    // 备注信息
    @Field(key: "notes")
    var notes: String?
    
    // 是否支持现代模式
    @Field(key: "modern")
    var modern: Bool?
    
    // 总帧数
    @Field(key: "total_frames")
    var totalFrames: Int?
    
    // 角色ID（外键）
    @Field(key: "character_id")
    var characterId: Int?
    
    var modernString: String {
        get {
            if modern == true {
                "经典&现代"
            } else {
                "仅经典模式"
            }
        }
    }
    
    var onHitString: String? {
        get {
            if ["KD", "HKD", "弹地"].contains(onHit) {
                return "击倒"
            } else {
                return onHit
            }
        }
    }
    
    var cancelString: String {
        get {
            if ["C", "SA", "SA1", "SA2", "SA3"].contains(cancel) {
                if (cancel == "C") {
                    return "可绿冲取消"
                } else {
                    return "可\(cancel!)取消"
                }
            }
            return ""
        }
    }
    
    /// 根据名称、输入指令或英文名称查找招式模型
    /// - Parameters:
    ///   - req: Vapor请求对象，用于数据库查询
    ///   - character: 角色模型，用于限定查询范围
    ///   - searchTerm: 搜索关键词，可能是招式名称、输入指令或英文名称
    /// - Returns: 匹配的招式模型，如果没有找到则返回nil
    public static func getModelBySearchTerm(req: Request, character: CharacterModel, searchTerm: String) async throws -> MoveModel? {
        // 确保角色ID存在
        guard let characterId = character.id else {
            return nil
        }
        
        // 预处理搜索词，移除前后空格并转为小写（不影响中文搜索）
        let normalizedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 并行执行多个查询，但按优先级处理结果
        // 1. 首先按中文名称搜索
        if let model = try await MoveModel.query(on: req.db)
            .filter(\MoveModel.$characterId == characterId)
            .filter(\MoveModel.$zhHansName == searchTerm) // 中文保持原样
            .first()
        {
            return model
        }
        
        // 2. 按输入指令搜索（例如：5LP、2MP等）
        if let model = try await MoveModel.query(on: req.db)
            .filter(\MoveModel.$characterId == characterId)
            .filter(\MoveModel.$input == normalizedSearchTerm)
            .first()
        {
            return model
        }
        
        // 3. 按英文名称搜索
        if let model = try await MoveModel.query(on: req.db)
            .filter(\MoveModel.$characterId == characterId)
            .filter(\MoveModel.$name == normalizedSearchTerm)
            .first()
        {
            return model
        }
        return nil
    }
    
    var description: String {
        get {
            var result = ""
            result += (input != nil) ? "指令:\(input!)\n" : ""
            result += (startup != nil) ? "前摇:\(startup!) " : ""
            result += (active != nil) ? "有效帧:\(active!) " : ""
            result += (recovery != nil) ? "后摇:\(recovery!)" : ""
            result += "\n"
            result += (onHitString != nil) ? "命中:\(onHitString!) " : ""
            result += (onBlock != nil) ? "被防:\(onBlock!) " : ""
            result += (baseDamage != nil) ? "基础伤害:\(baseDamage!)\n" : ""
            result += cancelString
            result += " \(modernString)"
            return result
        }
    }
    
    init() {}
}
