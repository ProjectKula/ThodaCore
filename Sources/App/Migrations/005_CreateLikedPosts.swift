//
//  005_CreateLikedPosts.swift
//
//
//  Created by Shrish Deshpande on 06/01/24.
//

import Fluent

struct CreateLikedPosts: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("likedPosts")
            .field("id", .uuid, .required)
            .field("postId", .string, .required, .references("posts", "id"))
            .field("userId", .int, .required, .references("registeredUsers", "id"))
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("likedPosts").delete()
    }
}
