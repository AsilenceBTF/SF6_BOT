//
//  FighterMatchesModel.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/3.
//
import Fluent
import Foundation

enum MatchStatus : String, Codable {
    case pending, completed
}

final class FighterMatchesModel : Model, @unchecked Sendable {
    static let schema: String = "fighter_matches"
    
    // 唯一标识符
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "first_user_id")
    var firstUID: Int
    
    @Field(key: "second_user_id")
    var secondUID: Int?
    
    @Field(key: "group_id")
    var groupId: Int
    
    @Field(key: "character_id")
    var characterID: Int?
    
    @Field(key: "notes")
    var notes: String?
    
    @Field(key: "score")
    var score: Int?
    
    @Field(key: "master_score")
    var masterScore: Int?
    
    @Enum(key: "match_status")
    var matchStatus: MatchStatus
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "update_time", on: .update)
    var updateTime: Date?
    
    init() {}
}
