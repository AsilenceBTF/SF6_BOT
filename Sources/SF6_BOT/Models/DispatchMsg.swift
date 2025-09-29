//
//  DispatchMsg.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/27.
//

import Vapor
struct QQDispatchMsgResult : Content {
    // event_id
    let id: String?
    // opcode
    let op: Int
    let s: String?
    // event type
    let t: String?
    // event real content
    let d: DispatchMsgData?
}

struct DispatchMsgData: Content {
    let id: String?
    let content: String?
    let timestamp: String?
    let author: DispatchAuthor?
    let groupId: String?
    let groupOpenid: String?
    let messageScene: DispatchMessageScene?
    let messageType: Int?
    
    // 处理 JSON 中的蛇形命名到驼峰命名的转换
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case timestamp
        case author
        case groupId = "group_id"
        case groupOpenid = "group_openid"
        case messageScene = "message_scene"
        case messageType = "message_type"
    }
}

// 作者信息
struct DispatchAuthor: Content {
    let id: String?
    let memberOpenid: String?
    let unionOpenid: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case memberOpenid = "member_openid"
        case unionOpenid = "union_openid"
    }
}

// 消息场景
struct DispatchMessageScene: Content {
    let source: String?
}
