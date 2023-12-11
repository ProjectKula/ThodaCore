//
//  003_CreateUserAuth.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Fluent

struct CreateUserAuth: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("userAuth")
            .field("id", .string, .required)
            .field("salt", .data, .required)
            .field("hash", .data, .required)
            .unique(on: "salt")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}
