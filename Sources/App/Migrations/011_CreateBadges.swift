//
//  011_CreateBadges.swift
//
//
//  Created by Shrish Deshpande on 19/06/24.
//

import Fluent

struct CreateBadges: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("badges")
            .field("id", .string, .required)
            .field("user_id", .int, .required, .references("registeredUsers", "id"))
            .field("created_at", .datetime, .required)
            .field("type", .string, .required)
            .unique(on: "id")
            .unique(on: "user_id", "type")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("badges").delete()
    }
}
