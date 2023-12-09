//
//  Schema.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Vapor
import Graphiti

struct AccountQuery: Encodable {}

let schema = try! Schema<Resolver, Request> {
    Scalar(UUID.self)
    Scalar(Date.self)

    Type(User.self) {
        Field("id", at: \.id)
        Field("name", at: \.name)
        Field("phone", at: \.phone)
        Field("email", at: \.email)
        Field("branch", at: \.branch)
        Field("gender", at: \.gender)
    }
    
    Type(RegisteredUser.self) {
        Field("id", at: \.id)
        Field("name", at: \.name)
        Field("phone", at: \.phone)
        Field("email", at: \.email)
        Field("personalEmail", at: \.personalEmail)
        Field("branch", at: \.branch)
        Field("gender", at: \.gender)
        Field("pronouns", at: \.pronouns)
        Field("dateRegistered", at: \.dateRegistered)
        Field("bio", at: \.bio)
    }

    Query {
        Field("allUsers", at: Resolver.getAllUsers)
        Field("allRegisteredUsers", at: Resolver.getAllRegisteredUsers)
        Field("getRegisteredUser", at: Resolver.getRegisteredUser) {
            Argument("id", at: \.id)
        }
        Field("getUser", at: Resolver.getUser) {
            Argument("id", at: \.id)
            Argument("email", at: \.email)
        }
    }
}
