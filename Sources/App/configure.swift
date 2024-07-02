import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Smtp
import Redis
import JWT
import Leaf

var appConfig: AppConfig = .init()

public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRegisteredUser())
    app.migrations.add(CreateUserAuth())
    app.migrations.add(CreatePosts())
    app.migrations.add(CreateLikedPosts())
    app.migrations.add(CreateFollowers())
    app.migrations.add(CreateConfessions())
    app.migrations.add(CreateLikedConfessions())
    app.migrations.add(CreateAttachments())
    app.migrations.add(CreateNotifications())
    app.migrations.add(CreateBadges())
    
    appConfig = AppConfig.firstLoad()

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: appConfig.postgres.host,
        port: appConfig.postgres.port,
        username: appConfig.postgres.username,
        password: appConfig.postgres.password,
        database: appConfig.postgres.database,
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql, isDefault: true)

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
    
    app.smtp.configuration.hostname = appConfig.smtp.host
    app.smtp.configuration.signInMethod = .credentials(
        username: appConfig.smtp.email,
        password: appConfig.smtp.password
    )
    app.smtp.configuration.port = appConfig.smtp.port
    app.smtp.configuration.secure = .startTls
    
    app.redis.configuration = try .init(hostname: appConfig.redis.host)
    
    app.passwords.use(.bcrypt(cost: appConfig.auth.bcryptCost))
    
//    app.jwt.google.gSuiteDomainName = appConfig.external.googleWorkspaceDomain
    app.jwt.signers.use(.hs256(key: appConfig.auth.signingKey))

    app.r2.configuration.endpoint = appConfig.r2.endpoint
    app.r2.configuration.secretKey = appConfig.r2.secretKey

    app.routes.defaultMaxBodySize = "8mb"

    app.views.use(.leaf)

    // register routes
    try routes(app)
}
