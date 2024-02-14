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
        Field("id", at: \.id)
        Field("collegeId", at: \.$collegeId.id)
        Field("name", at: \.name)
        Field("phone", at: \.phone)
        Field("email", at: \.email)
        Field("personalEmail", at: \.personalEmail)
        Field("branch", at: \.branch)
        Field("gender", at: \.gender)
        Field("pronouns", at: \.pronouns)
        Field("dateRegistered", at: \.dateRegistered?.timeIntervalSince1970)
        Field("bio", at: \.bio)
        Field("posts", at: RegisteredUser.getPosts)
    }
    
    Type(Post.self) {
        Field("id", at: \.id)
        Field("creatorId", at: \.$creator.id)
        Field("creator", at: Post.getCreator)
        Field("content", at: \.content)
        Field("createdAt", at: \.createdAt?.timeIntervalSince1970)
        Field("deleted", at: \.deleted)
        Field("likes", at: Post.getLikes) // TODO: use pagination
        Field("likesCount", at: Post.getLikesCount)
    }

    Query {
        Field("self", at: Resolver.getSelf)
        Field("user", at: Resolver.getRegisteredUser) {
            Argument("id", at: \.id)
        }
        Field("posts", at: Resolver.getPostsByUser) {
            Argument("creator", at: \.id)
        }
        Field("post", at: Resolver.getPostById) {
            Argument("id", at: \.id)
        }
        Field("recentPosts", at: Resolver.getRecentPosts) {
            Argument("count", at: \.count)
            Argument("before", at: \.before)
        }
    }
    
    Mutation {
        Field("editProfile", at: Resolver.editProfile) {
            Argument("gender", at: \.gender)
            Argument("bio", at: \.bio)
            Argument("pronouns", at: \.pronouns)
            Argument("personalEmail", at: \.personalEmail)
        }
        Field("createPost", at: Resolver.createPost) {
            Argument("content", at: \.content)
        }
        Field("deletePost", at: Resolver.deletePost) {
            Argument("id", at: \.id)
        }
        Field("restorePost", at: Resolver.restorePost) {
            Argument("id", at: \.id)
        }
        Field("likePost", at: Resolver.likePost) {
            Argument("post", at: \.post)
        }
        Field("unlikePost", at: Resolver.unlikePost) {
            Argument("post", at: \.post)
        }
    }
}
