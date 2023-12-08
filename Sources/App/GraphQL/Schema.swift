//
//  Schema.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Vapor
import Graphiti

let schema = try! Schema<Resolver, Request> {
    Scalar(UUID.self)

    Type(User.self) {
        Field("id", at: \.id)
        Field("usn", at: \.usn)
        Field("name", at: \.name)
        Field("phone", at: \.phone)
        Field("email", at: \.email)
        Field("branch", at: \.branch)
        Field("gender", at: \.gender)
    }

    Query {
        Field("allUsers", at: Resolver.getAllUsers)
    }
}
