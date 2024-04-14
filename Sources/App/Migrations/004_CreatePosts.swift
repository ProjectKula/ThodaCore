//
//  004_CreatePosts.swift
//
//
//  Created by Shrish Deshpande on 05/01/24.
//

import Fluent

struct CreatePosts: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("posts")
            .field("id", .string, .required)
            .field("user_id", .int, .required, .references("registeredUsers", "id"))
            .field("content", .string, .required)
            .field("created_at", .datetime, .required)
            .field("deleted_at", .datetime)
            .field("reply_id", .string, .references("posts", "id"))
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("posts").delete()
    }
}
