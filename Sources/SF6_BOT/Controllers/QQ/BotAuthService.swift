import Vapor
import Foundation

actor TokenManager {
    private var currentAccessToken: String?
    private var tokenExpiry: Date?
    private let logger = Logger(label: "app.auth.TokenManager")
    
    func getValidToken() -> (isValid: Bool, token: String?) {
        logger.info("tokenExpiry:\(String(describing: tokenExpiry))")
        logger.info("Date:\(Date().addingTimeInterval(60))")
        if let token = currentAccessToken,
           let expiry = tokenExpiry,
           expiry > Date().addingTimeInterval(60) {
            return (true, token)
        }
        return (false, nil)
    }
    
    func updateToken(_ token: String, expiresIn: Int) {
        self.currentAccessToken = token
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    func clearToken() {
        self.currentAccessToken = nil
        self.tokenExpiry = nil
    }
}

final class BotAuthService : Sendable {
    private let appId: String = Environment.get("APP_ID") ?? ""
    private let clientSecret: String = Environment.get("APP_SECRET") ?? ""
    private let httpClient: any Client
    private let tokenManager = TokenManager()
    
    init(httpClient: any Client) {
        self.httpClient = httpClient
    }
    
    func getValidToken() async throws -> String {
        let promise = httpClient.eventLoop.makePromise(of: String.self)
        
        // 由于Actor方法需要async context，我们需要在后台处理
        httpClient.eventLoop.execute {
            Task {
                let tokenState = await self.tokenManager.getValidToken()
                
                if tokenState.isValid, let token = tokenState.token {
                    promise.succeed(token)
                    return
                }
                
                do {
                    let newToken = try await self.fetchNewAccessToken()
                    promise.succeed(newToken)
                } catch {
                    promise.fail(error)
                }
            }
        }
        let token = try await promise.futureResult.get()
        return token
    }
    
    private func fetchNewAccessToken() async throws -> String {
        let url = "https://bots.qq.com/app/getAppAccessToken"
        let requestBody: [String: String] = [
            "appId": self.appId,
            "clientSecret": self.clientSecret
        ]
        
        let response = try await httpClient.post(URI(string: url)) { postRequest in
            try postRequest.content.encode(requestBody, as: .json)
        }.get()
        
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "getAppAccessToken:Failed to get access token: \(response.status)")
        }
        
        let authResponse = try response.content.decode(QQAuthResponse.self)
        
        await tokenManager.updateToken(authResponse.access_token, expiresIn: authResponse.expiresInNumber)
        
        return authResponse.access_token
    }
}
