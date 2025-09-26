//
//  QQVerification.swift
//  hello
//
//  Created by ByteDance on 2025/9/27.
//
import Vapor

// 定义请求和响应的数据结构
struct QQBotCallbackRequest: Content {
    let d: CallbackData
    let op: Int
}

struct CallbackData: Content {
    let plain_token: String?
    let event_ts: String?
}

struct QQBotVerificationResponse: Content {
    let plain_token: String
    let signature: String
}
