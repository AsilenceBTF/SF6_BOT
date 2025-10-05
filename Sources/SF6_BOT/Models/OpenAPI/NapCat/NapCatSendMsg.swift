//
//  NapCatSendMsg.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/3.
//
import Vapor

struct NapCatSendMsg : Content {
    let group_id: Int64?
    let user_id: Int64?
    let message: String?
}
