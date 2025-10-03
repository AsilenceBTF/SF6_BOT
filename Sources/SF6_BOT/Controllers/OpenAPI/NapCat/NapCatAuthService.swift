//
//  NapCatAuthService.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/3.
//
import Vapor

final class NapCatAuthService : Sendable {
    private let _token: String = Environment.get("ONEBOT_TOKEN") ?? ""
    func getValidToken() -> String {
        return _token
    }
}
