import Vapor
import Fluent
import FluentMySQLDriver

// configures your application
public func configure(_ app: Application) async throws {
    if app.environment == .development ||
       app.environment == .testing {
        app.middleware.use(RequestLoggingMiddleware())
    }
    
    app.middleware.use(RequestPerformanceMiddleware.shared)

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

    // register routes
    try routes(app)
}
