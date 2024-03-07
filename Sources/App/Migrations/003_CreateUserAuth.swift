//
//  003_CreateUserAuth.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Fluent

struct CreateUserAuth: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.transaction { db in
            db.schema("passwords")
                .field("id", .int, .required, .references("registeredUsers", "id"))
                .field("digest", .string, .required)
                .create()
                .flatMap { _ in
                    return db.enum("id_provider")
                        .case("apple")
                        .case("google")
                        .case("microsoft")
                        .case("discord")
                        .case("github")
                        .case("linkedIn")
                        .create()
                }
                .flatMap { type in
                    return db.schema("user_oidc")
                        .field("id", .uuid, .required)
                        .field("user_id", .int, .required, .references("registeredUsers", "id"))
                        .field("idp", type, .required)
                        .field("openid", .string, .required)
                        .field("url", .string)
                        .unique(on: "id")
                        .unique(on: "idp", "openid")
                        .create()
                }
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.transaction { db in
            return db.schema("user_oidc").delete()
                .flatMap { _ in
                    return db.enum("id_provider").delete()
                }
                .flatMap { _ in
                    return db.schema("passwords").delete()
                }
        }
    }
}
