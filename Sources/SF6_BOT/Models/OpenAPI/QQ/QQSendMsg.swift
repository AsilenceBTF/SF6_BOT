//
//  SendMsg.swift
//  SF6_BO
//
//  Created by ByteDance on 2025/9/25.
//

import Vapor

struct QQSendMsgContent: Content {
    let content: String
    let msg_type: Int
    let event_id: String
    let msg_id: String
}
