@testable import SF6_BOT
import VaporTesting
import Testing
import Fluent
import Foundation

@Suite("App Tests")
struct SF6_BOT_Tests {
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
    
    // 测试拼音
    @Test func testPinyin() async throws {
        try await withApp(configure: configure) { app in
            print("************开始测试拼音")
            let c = try await CharacterModel.query(on: app.db).all()
            for xc in c {
                print("原名:\(xc.chineseName) Pinyin:\(xc.chineseName.pinyin)")
            }
            print("************完成测试拼音")
        }
    }

    private func getDispatchResult() -> QQDispatchMsgResult {
        let author = DispatchAuthor(id: "8593AFE4EB5F94ADA7DD8336EB606CA7", memberOpenid: "8593AFE4EB5F94ADA7DD8336EB606CA7", unionOpenid: "8593AFE4EB5F94ADA7DD8336EB606CA7")
        let scene = DispatchMessageScene(source: "default")
        let d = DispatchMsgData(id: "ROBOT1.0_il.OURCnafnjcLHIRCudjvZSvqh0DXU.vBnlPXkJfzYyJwQWpVl9kBHltZchpMfEBk7Jy2zfNN0KzVxT6gLmdT8MY1zFcKgWhNBXAssG6u0!", content: " /帧数查询 劳丧 5lp", timestamp: "2025-09-29T20:03:38+08:00", author: author, groupId: "990FD9BBE0179A1E45F0074D77B660F2", groupOpenid: "990FD9BBE0179A1E45F0074D77B660F2", messageScene: scene, messageType: 0)
        return QQDispatchMsgResult(id: "GROUP_AT_MESSAGE_CREATE:ilourcnafnjclhircudjqsv08ocexcp6ygt7chdo51xqkgxwpynhysl6q6ws849", op: 0, s: nil, t: "GROUP_AT_MESSAGE_CREATE", d: d)
    }
    
    // 帧数查询
    @Test func testFrameQuery() async throws {
        var dispatch = getDispatchResult()
        dispatch.d?.content = " /帧数查询 劳丧 5lp"
        try await withApp(configure: configure) { app in
            try await app.testing().test(.POST, "recmsg/qbot", beforeRequest: { req in
                try req.content.encode(dispatch)
            })
        }
    }
    
    // 绿冲查询
    @Test func testChainQuery() async throws {
        var dispatch = getDispatchResult()
        dispatch.d?.content = "/可绿冲取消 朱莉"
        try await withApp(configure: configure) { app in
            try await app.testing().test(.POST, "recmsg/qbot", beforeRequest: { req in
                try req.content.encode(dispatch)
            })
        }
    }
    
    // mysql测试
    @Test func testQQUserModel() async throws {
        try await withApp(configure: configure) { app in
            sleep(3)
            let newUser = QQUserModel()
            newUser.userId = 3415177008
            newUser.nikeName = "瓜森塞今晚吃了吗？"
            try await newUser.save(on: app.db)
        }
    }
}


extension String {
    func toDictionary() -> [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("转换失败: \(error)")
            return nil
        }
    }
}
