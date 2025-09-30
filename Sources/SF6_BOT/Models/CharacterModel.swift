//
//  Characters.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/29.
//

import Vapor
import Fluent

final class CharacterAliasModel: @unchecked Sendable, Model {
    static let schema: String = "character_aliases"
    
    // 唯一标识符。
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "alias")
    var aliasName: String
    
    @Field(key: "character_id")
    var characterID: Int
    
    @Field(key: "pinyin")
    var pinyin: String?
    
    init() { }
}

final class CharacterModel: @unchecked Sendable, Model {
    static let schema: String = "characters"
    
    // 唯一标识符。
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "zh_hans_name")
    var chineseName: String
    
    static func getModelFromName(db: any Database, character: String) async throws -> CharacterModel? {
        let pinyinStr = character.pinyin
        return try await CharacterModel.query(on: db)
            .join(CharacterAliasModel.self, on: \CharacterAliasModel.$characterID == \CharacterModel.$id)
            .filter(CharacterAliasModel.self, \CharacterAliasModel.$pinyin == pinyinStr)
            .first()
    }
    
    init() { }
}
