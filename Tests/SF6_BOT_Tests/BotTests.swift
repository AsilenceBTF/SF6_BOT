@testable import SF6_BOT
import VaporTesting
import Testing
import Fluent

@Suite("App Tests")
struct SF6_BOT_Tests {
    private let logger: Logger = Logger(label: "com.app.test")
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

    @Test func frameDataText() async throws {
        try await withApp(configure: configure) { app in
            
            let result = try await CharacterModel.query(on: app.db)
                .join(CharacterAliasModel.self, on: \CharacterAliasModel.$characterID == \CharacterModel.$id)
                .filter(CharacterAliasModel.self, \CharacterAliasModel.$aliasName == "老桑")
                .first()

            if let final_result = result {
                print("*******name:\(final_result.name)")
            }
        }
    }
    
    
    @Test func testEnv() async throws {
        try await withApp(configure: configure) { app in
            let a = Environment.get("OPENAPI_URL")
            print("**********\(a)")
        }

    }
}
