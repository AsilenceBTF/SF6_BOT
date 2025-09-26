import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.post("recmsg", "qbot") { req -> QQBotVerificationResponse in
        let verificationService = QQBotVerificationService()
        return try verificationService.handleVerification(req: req)
    }
}
