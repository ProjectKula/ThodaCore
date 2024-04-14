//
//  005_CreateLikedConfessions.swift
//
//
//  Created by Shrish Deshpande on 14/04/24.
//

import Fluent

struct CreateLikedConfessions: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("likedConfessions")
            .field("id", .uuid, .required)
            .field("confessionId", .int, .required, .references("confessions", "id"))
            .field("userId", .int, .required, .references("registeredUsers", "id"))
            .unique(on: "id")
            .unique(on: "confessionId", "userId")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("likedConfessions").delete()
    }
}
