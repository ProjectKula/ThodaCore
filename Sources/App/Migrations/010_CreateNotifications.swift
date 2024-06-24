//
//  009_CreateAttachments.swift
//
//
//  Created by Shrish Deshpande on 19/06/24.
//

import Fluent

struct CreateNotifications: AsyncMigration {
    func prepare(on database: Database) async throws {
        return try await database.transaction { db in
            let type = try await db.enum("notification_type")
              .case("follow")
              .case("like")
              .case("comment")
              .case("mention")
              .create()
            try await db.schema("notifications")
              .field("id", .string, .required)
              .field("target_user_id", .int, .references("registeredUsers", "id"))
              .field("target_post_id", .string, .references("posts", "id"))
              .field("created_at", .datetime, .required)
              .field("deleted_at", .datetime)
              .field("type", type, .required)
              .unique(on: "id")
                  .create()
        }
    }

    func revert(on database: Database) async throws {
        return try await database.schema("notifications").delete()
    }
}
