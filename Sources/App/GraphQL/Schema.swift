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
        Field("collegeId", at: \.id)
        Field("name", at: \.name)
        Field("phone", at: \.phone)
        Field("email", at: \.email)
        Field("branch", at: \.branch)
        Field("gender", at: \.gender)
    }
    
    Type(RegisteredUser.self) {
        Field("collegeId", at: \.id)
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
    
    Type(Post.self) {
        Field("id", at: \.id)
        Field("creator", at: \.creator)
        Field("content", at: \.content)
        Field("createdAt", at: \.createdAt?.timeIntervalSince1970)
        Field("deleted", at: \.deleted)
    }

    Query {
        Field("unregisteredUsers", at: Resolver.getAllUsers)
        Field("unregisteredUser", at: Resolver.getUser) {
            Argument("id", at: \.id)
            Argument("email", at: \.email)
        }
        Field("users", at: Resolver.getAllRegisteredUsers)
        Field("user", at: Resolver.getRegisteredUser) {
            Argument("id", at: \.id)
        }
        Field("posts", at: Resolver.getPostsByUser) {
            Argument("creator", at: \.id)
        }
        Field("post", at: Resolver.getPostsByUser) {
            Argument("id", at: \.id)
        }
    }
    
    Mutation {
        Field("editUserInfo", at: Resolver.editUserInfo) {
            Argument("id", at: \.id)
            Argument("gender", at: \.gender)
            Argument("bio", at: \.bio)
            Argument("pronouns", at: \.pronouns)
            Argument("personalEmail", at: \.personalEmail)
        }
        Field("createPost", at: Resolver.createPost) {
            Argument("creator", at: \.creator)
            Argument("content", at: \.content)
        }
        Field("deletePost", at: Resolver.deletePost) {
            Argument("id", at: \.id)
        }
        Field("restorePost", at: Resolver.restorePost) {
            Argument("id", at: \.id)
        }
        Field("likePost", at: Resolver.likePost) {
            Argument("user", at: \.user)
            Argument("post", at: \.post)
        }
        Field("unlikePost", at: Resolver.unlikePost) {
            Argument("user", at: \.user)
            Argument("post", at: \.post)
        }
    }
}
