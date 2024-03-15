//
//  S3.swift
//
//
//  Created by Shrish Deshpande on 11/03/24.
//

import Vapor

extension Application {
    public var s3: S3 {
        .init(application: self)
    }
    
    public struct S3 {
        let application: Application

        struct ConfigKey: StorageKey {
            typealias Value = S3Configuration
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
