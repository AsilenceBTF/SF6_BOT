import Vapor
import Fluent
import FluentMySQLDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    if app.environment == .development ||
       app.environment == .testing {
        app.middleware.use(RequestLoggingMiddleware())
    }

    try ChinesePinyinConverter.initialize(fileName: "unicode_to_hanyu_pinyin")
    
    let botAuthService = BotAuthService(httpClient: app.client)
    BotOpenAPI.configure(authService: botAuthService, httpClient: app.client)
    
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
