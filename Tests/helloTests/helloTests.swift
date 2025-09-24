@testable import hello
import VaporTesting
import Testing

@Suite("App Tests")
struct helloTests {
    private let appId = "102809211"
    private let clientSecret = "OyY8iJuV6hItV7jLxZBoR4hKxaDrV9nR"
    
    
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
            let botAuth = BotAuthService(appId: appId, clientSecret: clientSecret, httpClient: app.client)
            let token = try await botAuth.getValidToken()
            print("token:\(token)")
        }
    }
    
    @Test func sendMsgTest() async throws {
        try await withApp(configure: configure) { app in
            let botAuth = BotAuthService(appId: appId, clientSecret: clientSecret, httpClient: app.client)
            let openapi = BotOpenAPI(authService: botAuth, httpClient: app.client)
            let authResponse = try await openapi.sendMessage(msg: "大家好")
            print("id:\(authResponse.id)")
            print("id:\(authResponse.timestamp)")
        }
    }
    
}
