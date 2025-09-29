import Vapor

func routes(_ app: Application) throws {
    app.post("recmsg", "qbot") { req -> Response in
        let callbackRequest = try req.content.decode(QQBotVerificationRequest.self)
        switch callbackRequest.op {
        case 13:
            // 验证请求 - 返回 QQBotVerificationResponse
            let verificationService = QQBotVerificationService()
            return try verificationService.handleVerification(callbackRequest: callbackRequest)
        case 0:
            return try await ClientMessageController().handleDispatchMessage(req: req)
        default:
            return Response(status: .notImplemented)
        }
    }
}
