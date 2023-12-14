import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Smtp
import Redis
import JWT

struct AppConfig {
    static let databaseHost = Environment.get("DATABASE_HOST") ?? "localhost"
    static let databasePort = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432
    static let databaseUsername = Environment.get("DATABASE_USERNAME") ?? "postgres"
    static let databasePassword = Environment.get("DATABASE_PASSWORD") ?? "12345678"
    static let databaseName = Environment.get("DATABASE_NAME") ?? "postgres"
    static let defaultEmail = Environment.get("EMAIL_NAME") ?? "postalkings.postcrossing@gmail.com"
    static let smtpHost = Environment.get("EMAIL_SMTP") ?? "smtp.mail.me.com"
    static let smtpPassword = Environment.get("EMAIL_PASSWORD") ?? "NotMyEmailPassword"
    static let smtpPort = Environment.get("SMTP_PORT").flatMap(Int.init(_:)) ?? 587
    static let redisHost = Environment.get("REDIS_HOST") ?? "127.0.0.1"
    static let signupCodeExpireTime = Environment.get("SIGNUP_CODE_EXPIRE_TIME").flatMap(Int.init(_:)) ?? 600
    static let jwtSigningKey = Environment.get("JWT_SIGNING_KEY") ?? "secret"
}

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: AppConfig.databaseHost,
        port: AppConfig.databasePort,
        username: AppConfig.databaseUsername,
        password: AppConfig.databasePassword,
        database: AppConfig.databaseName,
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql, isDefault: true)
    
    app.smtp.configuration.hostname = AppConfig.smtpHost
    app.smtp.configuration.signInMethod = .credentials(
        username: AppConfig.defaultEmail,
        password: AppConfig.smtpPassword
    )
    app.smtp.configuration.port = AppConfig.smtpPort
    app.smtp.configuration.secure = .startTls
    
    app.redis.configuration = try .init(hostname: AppConfig.redisHost)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRegisteredUser())
    app.migrations.add(CreateUserAuth())
    
    app.jwt.signers.use(.hs256(key: AppConfig.jwtSigningKey))

    // register routes
    try routes(app)
}
