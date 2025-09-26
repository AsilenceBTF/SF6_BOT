//
//  QQBotVerificationService.swift
//  hello
//
//  Created by ByteDance on 2025/9/27.
//

import Vapor
import Crypto

final class QQBotVerificationService {
    private let clientSecret: String = Environment.get("APP_SECRET") ?? ""
    public func handleVerification(req: Request) throws -> QQBotVerificationResponse {
        let callbackRequest = try req.content.decode(QQBotCallbackRequest.self)

        // 只处理验证请求 (op == 13)
        guard callbackRequest.op == 13 else {
            throw Abort(.badRequest, reason: "非验证请求,op:\(callbackRequest.op)")
        }
        
        guard let plainToken = callbackRequest.d.plain_token else {
            throw Abort(.badRequest, reason: "缺少plain_token")
        }
        
        guard let eventTs = callbackRequest.d.event_ts else {
            throw Abort(.badRequest, reason: "缺少event_ts")
        }
        
        // 处理密钥，确保长度为32字节
        let processedSecret = processSecret(clientSecret)
        
        let responseSignature = try calculateResponseSignature(
            eventTs: eventTs,
            plainToken: plainToken,
            clientSecret: processedSecret
        )
        
        return QQBotVerificationResponse(plain_token: plainToken, signature: responseSignature)
    }
    
    private func processSecret(_ secret: String) -> String {
        var processedSecret = secret
        
        // 重复secret直到长度至少为32（模仿Python代码的逻辑）
        while processedSecret.utf8.count < 32 {
            processedSecret += secret
        }
        
        // 截取前32个字节
        let index32 = processedSecret.utf8.index(processedSecret.utf8.startIndex, offsetBy: 32)
        return String(processedSecret[processedSecret.startIndex..<index32])
    }
    
    /// 计算返回给QQ平台的响应签名
    private func calculateResponseSignature(eventTs: String, plainToken: String, clientSecret: String) throws -> String {
        let messageString = eventTs + plainToken
        
        guard let messageData = messageString.data(using: .utf8),
              let secretData = clientSecret.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "数据编码失败")
        }
        
        do {
            let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: secretData)
            let signature = try privateKey.signature(for: messageData)
            return signature.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            throw Abort(.internalServerError, reason: "响应签名计算失败: \(error)")
        }
    }
}
