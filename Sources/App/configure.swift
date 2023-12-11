import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Smtp

var thodaCoreEmail: String = ""

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "12345678",
        database: Environment.get("DATABASE_NAME") ?? "postgres",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql, isDefault: true)
    
    thodaCoreEmail = Environment.get("EMAIL_NAME") ?? "shrishvd.cy23@rvce.edu.in"
    app.smtp.configuration.hostname = "smtp.gmail.com"
    app.smtp.configuration.signInMethod = .credentials(
        username: thodaCoreEmail,
        password: Environment.get("EMAIL_PASSWORD") ?? "NotMyEmailPassword"
    )
    app.smtp.configuration.port = 587
    app.smtp.configuration.secure = .startTls

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRegisteredUser())
    app.migrations.add(CreateUserAuth())

    // register routes
    try routes(app)
}
