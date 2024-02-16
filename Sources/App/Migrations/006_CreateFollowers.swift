//
//  006_CreateFollowers.swift
//
//
//  Created by Shrish Deshpande on 16/02/24.
//

import Foundation

import Fluent

struct CreateFollowers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("followers")
            .field("id", .uuid, .required)
            .field("follower_id", .int, .required, .references("registeredUsers", "id"))
            .field("followed_id", .int, .required, .references("registeredUsers", "id"))
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("followers").delete()
    }
}
