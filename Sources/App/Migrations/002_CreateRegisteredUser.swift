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
            .field("id", .string, .required)
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
            .field("reg_no", .custom("serial"))
            .unique(on: "id")
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("registeredUsers").delete()
    }
}
