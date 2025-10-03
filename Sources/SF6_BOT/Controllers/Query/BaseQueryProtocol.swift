//
//  BaseQueryController.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/30.
//

import Vapor

protocol BaseQueryProtocol {
    func handle(req: Request, content: any Content, params: [String]) async throws -> String
}
