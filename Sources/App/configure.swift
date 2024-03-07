import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Smtp
import Redis
import JWT

struct AppConfig: Codable {
    var postgres: PostgresConfig = .init()
    var smtp: SmtpConfig = .init()
    var redis: RedisConfig = .init()
    var auth: AuthConfig = .init()
    var external: ExternalConfig = .init()
    
    struct PostgresConfig: Codable {
        var host: String = "localhost"
        var port: Int = 5432
        var username: String = "postgres"
        var password: String = "12345678"
        var database: String = "postgres"
    }
    
    struct SmtpConfig: Codable {
        var email: String = "postalkings.postcrossing@gmail.com"
        var host: String = "smtp.gmail.com"
        var password: String = "NotMyEmailPassword"
        var port: Int = 587
    }
    
    struct RedisConfig: Codable {
        var host: String = "127.0.0.1"
    }
    
    struct AuthConfig: Codable {
        var bcryptCost: Int = 8
        var signingKey: String = "secret"
        var signupCodeExpireTime: Int = 600
    }
    
    struct ExternalConfig: Codable {
        var googleWorkspaceDomain: String = "rvce.edu.in"
    }
}

extension AppConfig {
    static let path = Environment.get("THODACORE_CONFIG") ?? "Config.plist"
    
    static func firstLoad() -> AppConfig {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: AppConfig.path)) {
            do {
                return try PropertyListDecoder().decode(AppConfig.self, from: data)
            } catch {
                fatalError("Error decoding config file: \(error)")
            }
        } else {
            do {
                let config: AppConfig = .init()
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .xml
                let data = try encoder.encode(config)
                try data.write(to: URL(fileURLWithPath: AppConfig.path))
                return config
            } catch {
                fatalError("Error encoding config file: \(error)")
            }
        }
    }
}

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

    // register routes
    try routes(app)
}
