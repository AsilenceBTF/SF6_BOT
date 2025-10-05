import Vapor
import Fluent
import FluentMySQLDriver

// configures your application
public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    if app.environment == .development ||
       app.environment == .testing {
        // 请求测试日志
        app.middleware.use(RequestLoggingMiddleware())
    }
    
    // 注册性能埋点
//    app.middleware.use(RequestPerformanceMiddleware.shared)

    try ChinesePinyinConverter.initialize(fileName: "unicode_to_hanyu_pinyin")
    
    // QQ OpenAPI Config
    let botAuthService = QQBotAuthService(httpClient: app.client)
    QQBotOpenAPI.configure(authService: botAuthService, httpClient: app.client)
    
    // NapCat OpenAPI Config
    let napCatAuthService = NapCatAuthService()
    NapCatOpenAPI.configure(authService: napCatAuthService, httpClient: app.client)
    
    // Config Default API
    BotOpenAPIManager.configDefault(API: NapCatOpenAPI.shared)
    
    // config mysql
    let dataBase: String = Environment.get("MYSQL_NAME") ?? ""
    let password: String = Environment.get("MYSQL_PASSWORD") ?? ""

    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    let config = MySQLConfiguration(hostname: "127.0.0.1", port: 3306,username: "ltl", password: password, database: dataBase, tlsConfiguration: tls)
    app.databases.use(.mysql(configuration: config), as: .mysql)

    // 添加数据库迁移
    try await app.autoMigrate()
    
    // 启动战斗匹配清理服务
    app.matchesCleanupService.start()
    
    // register routes
    try routes(app)
}
