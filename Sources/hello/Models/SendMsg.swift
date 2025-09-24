//
//  SendMsg.swift
//  hello
//
//  Created by ByteDance on 2025/9/25.
//

import Vapor

struct SendMsgResponse: Content {
    let id: String
    let timestamp: String
}
