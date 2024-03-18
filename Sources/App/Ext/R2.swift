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

        public var configuration: S3Configuration {
            get {
                self.application.storage[ConfigKey.self] ?? .init()
            }
            nonmutating set {
                self.application.storage[ConfigKey.self] = newValue
            }
        }
    }
}
