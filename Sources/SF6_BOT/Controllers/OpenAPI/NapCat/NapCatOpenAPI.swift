//
//  NapCatOpenAPI.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/3.
//

import Vapor

final class NapCatOpenAPI : BotOpenAPI, @unchecked Sendable {
    private let authService: NapCatAuthService
    private let httpClient: any Client
    private let logger = Logger(label: "com.napcat.openapi")
    private static let isolationQueue = DispatchQueue(label: "com.napcat.openapi.isolation",
                                               attributes: .concurrent)
    // 从环境变量中获取OneBot服务器地址
    private let baseURL: String = Environment.get("ONEBOT_URL") ?? ""

    // 单例实例（延迟加载）
    nonisolated(unsafe) private static var _shared: NapCatOpenAPI?
    
    // 私有初始化方法
    init(authService: NapCatAuthService, httpClient: any Client) {
        self.authService = authService
        self.httpClient = httpClient
    }
    
    // 配置单例的方法
    public static func configure(authService: NapCatAuthService, httpClient: any Client) {
        isolationQueue.async(flags: .barrier) {
            _shared = NapCatOpenAPI(authService:authService, httpClient: httpClient)
        }
    }

    // 获取单例
    public static var shared: any BotOpenAPI {
        isolationQueue.sync {
            guard let instance = _shared else {
                fatalError("NapCatOpenAPI 未配置，请先调用 configure 方法")
            }
            return instance
        }
    }
    
    // 发送消息，支持OneBotMessage类型
    public func sendMessage(content: any Content, msg: String) {
        if let oneBotContent = content as? OneBotMessage {
            // 处理OneBot消息
            if oneBotContent.group_id != nil {
                var atUserMsg = msg
                // 添加at用户
                if let userId = oneBotContent.user_id {
                    atUserMsg = String.napCatCQString(userId: userId) + "\n" + msg
                }
                sendMsgToGroup(content: oneBotContent, msg: atUserMsg)
            } else if oneBotContent.user_id != nil {
                sendMsgToPrivate(content: oneBotContent, msg: msg)
            }
        }
    }
    
    private func sendMsgToGroup(content: OneBotMessage, msg: String) {
        Task {
            do {
                let token = authService.getValidToken()
                let requestContent = NapCatSendMsg(group_id: content.group_id, user_id: content.user_id, message: msg)
                _ = try await httpClient.post(URI(string: baseURL + "/send_group_msg")) { postRequest in
                    postRequest.headers.add(name: "Authorization", value: "Bearer \(token)")
                    try postRequest.content.encode(requestContent, as: .json)
                }.get()
            } catch {
                logger.error("napcat发送消息错误: \(error)")
            }
        }
    }
    
    private func sendMsgToPrivate(content: OneBotMessage, msg: String) {
        Task {
            do {
                let token = authService.getValidToken()
                let requestContent = NapCatSendMsg(group_id: content.group_id, user_id: content.user_id, message: msg)
                _ = try await httpClient.post(URI(string: baseURL + "/send_private_msg")) { postRequest in
                    postRequest.headers.add(name: "Authorization", value: "Bearer \(token)")
                    try postRequest.content.encode(requestContent, as: .json)
                }.get()
            } catch {
                logger.error("napcat发送消息错误: \(error)")
            }
        }
    }
    
    // 向OneBot消息发送回复 - 修复并发问题
    private func sendToOneBotMessage(content: OneBotMessage, msg: String) {
        Task {
//            do {
//                logger.debug("通过OneBot发送消息: \(msg)")
//                let token = authService.getValidToken()
                
//                {
//                  "group_id": "textValue",
//                  "message": []
//                }

//                // 根据消息类型决定发送目标
//                var messageType = "private"
//                var userId: String? = nil
//                var groupId: String? = nil
//                var replyMsgId: String? = nil
//                
//                if let messageTypeFromContent = content.message_type {
//                    messageType = messageTypeFromContent
//                }
//                
//                if let userIdFromContent = content.user_id {
//                    userId = userIdFromContent
//                }
//                
//                if let groupIdFromContent = content.group_id {
//                    groupId = groupIdFromContent
//                }
//                
//                replyMsgId = content.message_id
//                
//                // 构建OneBot发送消息请求
//                let messageRequest = OneBotSendMessageRequest(
//                    message_type: messageType,
//                    user_id: userId,
//                    group_id: groupId,
//                    message: AnyCodable(msg),
//                    auto_escape: false,
//                    reply: replyMsgId,
//                    at_sender: messageType == "group",
//                    at_all: false,
//                    face: nil,
//                    font: nil
//                )
//                
//                // 发送请求到OneBot服务器
//                let response = try await httpClient.post(URI(string: baseURL + "/send_msg")) {
//                    postRequest in
//                    try postRequest.content.encode(messageRequest, as: .json)
//                }.get()
//                
//                guard response.status == .ok else {
//                    throw Abort(.internalServerError, reason: "发送消息失败: \(response.status)")
//                }
//                
//                let result = try response.content.decode(OneBotSendMessageResponse.self)
//                logger.debug("发送消息成功，消息ID: \(result.data?.message_id ?? 0)")
//            } catch {
//                logger.error("napcat发送消息错误: \(error)")
//            }
        }
    }
}
