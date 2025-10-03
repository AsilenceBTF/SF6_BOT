//
//  NapCatSendMsg.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/3.
//
import Vapor

struct NapCatSendMsg : Content {
    let group_id: Int?
    let user_id: Int?
    let message: String?
}
