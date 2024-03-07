//
//  002_CreateRegisteredUser.swift
//  
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Fluent

struct CreateRegisteredUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("registeredUsers")
            .field("collegeId", .string, .required, .references("users", "id"))
            .field("name", .string, .required)
            .field("phone", .string, .required)
            .field("email", .string, .required)
            .field("personal_email", .string)
            .field("branch", .string, .required)
            .field("gender", .string, .required)
            .field("pronouns", .string)
            .field("date_registered", .datetime, .required)
            .field("bio", .string)
            .field("intake_year", .int, .required)
            .field("avatar_hash", .string)
            .field("id", .int, .custom("GENERATED ALWAYS AS IDENTITY"))
            .unique(on: "collegeId")
            .unique(on: "email")
            .unique(on: "id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("registeredUsers").delete()
    }
}
