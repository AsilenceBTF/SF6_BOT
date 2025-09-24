//
//  OpenAPI.swift
//  hello
//
//  Created by ByteDance on 2025/9/25.
//

import Vapor

final class BotOpenAPI {
    private let authService: BotAuthService
    private let httpClient: any Client
    private let logger = Logger(label: "app.openApi.log")
    private let url = "https://api.sgroup.qq.com"

    init(authService: BotAuthService, httpClient: any Client) {
        self.authService = authService
        self.httpClient = httpClient
    }
    
    public func sendMessage(msg: String) async throws -> SendMsgResponse {
        let token = try await authService.getValidToken()
        
        let requestBody: [String: String] = [
            "content": msg,
            "msg_type": "0"
        ]
        
        let response = try await httpClient.post(URI(string: url + "/v2/groups/482412276/messages")) { postRequest in
            postRequest.headers.add(name: "Authorization", value: "QQBot \(token)")
            try postRequest.content.encode(requestBody, as: .json)
        }.get()
        
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to get access token: \(response.status)")
        }
        
        let authResponse = try response.content.decode(SendMsgResponse.self)
        return authResponse
    }
}
