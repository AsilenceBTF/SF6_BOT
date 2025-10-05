//
//  QQUserModel.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/3.
//
import Fluent

final class QQUserModel : Model, @unchecked Sendable {
    static let schema: String = "qq_users"
    
    // 唯一标识符
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "user_id")
    var userId: Int
    
    @Field(key: "nike_name")
    var nikeName: String
    
    init() {}
}
