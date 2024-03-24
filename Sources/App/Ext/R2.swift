//
//  R2.swift
//
//
//  Created by Shrish Deshpande on 11/03/24.
//

import Vapor

extension Application {
    public var r2: R2 {
        .init(application: self)
    }
    
    public struct R2 {
        let application: Application

        struct ConfigKey: StorageKey {
            typealias Value = R2Configuration
        }

        public func post(data: Data, name: String) async throws {
            let config = self.configuration
            let uri: URI = URI(string: config.endpoint + name)
            let response = try await application.client.post(uri) { req in
                try req.content.encode(data)
                req.headers.add(name: "X-Auth-Key", value: config.secretKey)
            }
            application.logger.info("Uploaded data to \(uri) with status \(response.status)")
        }

        public var configuration: R2Configuration {
            get {
                self.application.storage[ConfigKey.self] ?? .init(secretKey: "", endpoint: "")
            }
            nonmutating set {
                self.application.storage[ConfigKey.self] = newValue
            }
        }
    }
}

extension Data: Content {
    
}
