//
//  OpenAPI.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/9/25.
//

import Vapor

final class QQBotOpenAPI : @unchecked Sendable, BotOpenAPI {
    private let authService: QQBotAuthService
    private let httpClient: any Client
    private let logger = Logger(label: "com.qqbot.openapi")
    private let baseURL: String = Environment.get("OPENAPI_URL") ?? ""
    
    private static let isolationQueue = DispatchQueue(label: "com.qqbot.openapi.isolation",
                                               attributes: .concurrent)
    
    // 单例实例（延迟加载）
    nonisolated(unsafe) private static var _shared: QQBotOpenAPI?
    
    // 私有初始化方法
    private init(authService: QQBotAuthService, httpClient: any Client) {
        self.authService = authService
        self.httpClient = httpClient
    }
    
    // 配置单例的方法
    public static func configure(authService: QQBotAuthService,
                               httpClient: any Client) {
        isolationQueue.async(flags: .barrier) {
            _shared = QQBotOpenAPI(authService: authService,
                               httpClient: httpClient)
        }
    }
    
    // 获取单例
    public static var shared: any BotOpenAPI {
        isolationQueue.sync {
            guard let instance = _shared else {
                fatalError("QQBotOpenAPI 未配置，请先调用 configure 方法")
            }
            return instance
        }
    }

    public func sendMessage(content: any Content, msg: String) {
        guard let dispathRequest = content as? QQDispatchMsgResult else {
            logger.error("sendMsg Error:content不是QQDispatchMsgResult类型")
            return
        }
        Task {
            do {
                let token = try await authService.getValidToken()
                
                logger.debug("sendMessage:\(msg)")
                
                let requestContent: QQSendMsgContent = QQSendMsgContent(
                    content: msg,
                    msg_type: 0,
                    event_id: dispathRequest.id ?? "",
                    msg_id: dispathRequest.d?.id ?? ""
                )
                
                let groupOpenid = dispathRequest.d?.groupOpenid ?? ""
                
                let response = try await httpClient.post(URI(string: baseURL + "/v2/groups/\(groupOpenid)/messages")) { postRequest in
                    postRequest.headers.add(name: "Authorization", value: "QQBot \(token)")
                    try postRequest.content.encode(requestContent, as: .json)
                }.get()
                
                guard response.status == .ok else {
                    throw Abort(.internalServerError, reason: "sendMessage:Failed to get access token: \(response.status)")
                }
            } catch {
                logger.error("sendMsg Error:\(error)")
            }
        }
    }
}
