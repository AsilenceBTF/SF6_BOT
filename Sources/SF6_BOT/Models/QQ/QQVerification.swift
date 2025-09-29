//
//  QQVerification.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/27.
//
import Vapor

// 定义请求和响应的数据结构
struct QQBotVerificationRequest: Content {
    let d: VerificationData
    let op: Int
}

struct VerificationData: Content {
    let plain_token: String?
    let event_ts: String?
}

struct QQBotVerificationResponse: Content {
    let plain_token: String
    let signature: String
}
