//
//  Request+Loaders.swift
//
//
//  Created by Shrish Deshpande on 03/07/24.
//

import Vapor
import Fluent
import DataLoader

extension Request {
    var loaders: DataLoaders {
        get {
            self.storage[DataLoadersStorageKey.self]!
        }
        set {
            self.storage[DataLoadersStorageKey.self] = newValue
        }
    }
}
