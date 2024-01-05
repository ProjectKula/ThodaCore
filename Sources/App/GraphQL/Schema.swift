//
//  Schema.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Foundation
import Vapor
import Graphiti

struct AccountQuery: Encodable {}

let schema = try! Schema<Resolver, Request> {
    Scalar(UUID.self)
    Scalar(Date.self)

    Type(UnregisteredUser.self) {
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
        Field("dateRegistered", at: \.dateRegistered?.timeIntervalSince1970)
        Field("bio", at: \.bio)
    }

    Query {
        Field("unregisteredUsers", at: Resolver.getAllUsers)
        Field("unregisteredUser", at: Resolver.getUser) {
            Argument("id", at: \.id)
            Argument("email", at: \.email)
        }
        
        Field("users", at: Resolver.getAllRegisteredUsers)
        Field("user", at: Resolver.getRegisteredUser) {
            Argument("regNo", at: \.regNo)
        }
    }
    
    Mutation {
        Field("editUserInfo", at: Resolver.editUserInfo)
    }
}
