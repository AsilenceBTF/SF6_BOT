//
//  SendMsg.swift
//  SF6_BO
//
//  Created by ByteDance on 2025/9/25.
//

import Vapor

struct SendMsgResponse: Content {
    let id: String
    let timestamp: String
}

struct SendMsgContent: Content {
    let content: String
    let msg_type: Int
    let event_id: String
    let msg_id: String
}
