//
//  first.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/24.
//

import Vapor

struct QQAuthResponse: Content {
    let access_token: String
    let expires_in: String
    var expiresInNumber: Int {
        get {
            Int(expires_in) ?? 0
        }
    }
}
