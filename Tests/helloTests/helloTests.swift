@testable import hello
import VaporTesting
import Testing

@Suite("App Tests")
struct helloTests {
    private let appId: String = Environment.get("APP_ID") ?? ""
    private let clientSecret: String = Environment.get("APP_SECRET") ?? ""
    
    @Test func env() async throws {
        try await withApp(configure: configure) { app in
            print("app_id:\(appId)")
            print("clientSecret:\(clientSecret)")
        }
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "hello", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            })
        }
    }
    
    @Test func botAuthTest() async throws {
        try await withApp(configure: configure) { app in
            let botAuth = BotAuthService(httpClient: app.client)
            let token = try await botAuth.getValidToken()
            print("token:\(token)")
        }
    }
    
    @Test func sendMsgTest() async throws {
        try await withApp(configure: configure) { app in
            let botAuth = BotAuthService(httpClient: app.client)
            let openapi = BotOpenAPI(authService: botAuth, httpClient: app.client)
            let authResponse = try await openapi.sendMessage(msg: "大家好")
            print("id:\(authResponse.id)")
            print("id:\(authResponse.timestamp)")
        }
    }
    
}
