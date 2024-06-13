//
//  AppConfig.swift
//
//
//  Created by Shrish Deshpande on 09/03/24.
//

import Foundation
import Vapor

struct AppConfig: Codable {
    var postgres: PostgresConfig = .init()
    var smtp: SmtpConfig = .init()
    var redis: RedisConfig = .init()
    var auth: AuthConfig = .init()
    var external: ExternalConfig = .init()
    var r2: R2Config = .init()

    init() {
    }

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
        var signingKey: String = "secret" // TODO: 
        var signupCodeExpireTime: Int = 600
    }

    struct ExternalConfig: Codable {
        var googleWorkspaceDomain: String = "rvce.edu.in"
    }

    struct R2Config: Codable {
        var endpoint: String = "http://localhost:8787"
        var secretKey: String = "secret" // TODO:
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
