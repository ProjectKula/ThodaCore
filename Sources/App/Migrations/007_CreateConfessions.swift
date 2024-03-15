//
//  007_CreateConfessions.swift
//
//
//  Created by Shrish Deshpande on 19/02/24.
//

import Fluent

struct CreateConfessions: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("confessions")
            .field("id", .int, .custom("GENERATED ALWAYS AS IDENTITY"))
            .field("creator", .int, .required, .references("registeredUsers", "id"))
            .field("content", .string, .required)
            .field("created_at", .datetime, .required)
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("confessions").delete()
    }
}
