//
//  009_CreateAttachments.swift
//
//
//  Created by Shrish Deshpande on 19/06/24.
//

import Fluent

struct CreateAttachments: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("attachments")
            .field("id", .string, .required)
            .field("parentId", .string, .required)
            .field("hash", .string, .required)
            .unique(on: "hash")
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("attachments").delete()
    }
}
