import Fluent

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .id()
            .field("usn", .string, .required)
            .field("name", .string, .required)
            .field("phone", .string)
            .field("email", .string, .required)
            .field("branch", .string, .required)
            .field("gender", .string, .required)
            .unique(on: "usn")
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}
