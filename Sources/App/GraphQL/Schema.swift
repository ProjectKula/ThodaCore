//
//  Schema.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Foundation
import Vapor
import Fluent
import Graphiti

struct AccountQuery: Encodable {}

let schema = try! Graphiti.Schema<Resolver, Request> {
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
        Field("posts", at: RegisteredUser.getPosts) {
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
        Field("followers", at: RegisteredUser.getFollowers) {
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
        Field("followerCount", at: RegisteredUser.getFollowerCount)
        Field("following", at: RegisteredUser.getFollowing) {
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
        Field("followingCount", at: RegisteredUser.getFollowingCount)
        Field("isSelf", at: RegisteredUser.isSelf)
        Field("followedBySelf", at: RegisteredUser.followedBySelf)
        Field("followsSelf", at: RegisteredUser.followsSelf)
        Field("avatarHash", at: \.avatarHash)
    }
    
    Type(Post.self) {
        Field("id", at: \.id)
        Field("creatorId", at: \.$creator.id)
        Field("creator", at: Post.getCreator)
        Field("content", at: \.content)
        Field("createdAt", at: \.createdAt?.timeIntervalSince1970)
        Field("deletedAt", at: \.deletedAt?.timeIntervalSince1970)
        Field("likes", at: Post.getLikes) {
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
        Field("likesCount", at: Post.getLikesCount)
        Field("selfLiked", at: Post.selfLiked)
        Field("replies", at: Post.getReplies) {
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
    }
    
    Type(Confession.self) {
        Field("id", at: \.id)
        Field("content", at: \.content)
        Field("createdAt", at: \.createdAt?.timeIntervalSince1970)
        Field("deletedAt", at: \.deletedAt?.timeIntervalSince1970)
    }
    
    Type(PageMetadata.self) {
        Field("page", at: \.page)
        Field("per", at: \.per)
        Field("total", at: \.total)
        Field("pageCount", at: \.pageCount)
    }
    
    Type(Page<Confession>.self) {
        Field("items", at: \.items)
        Field("metadata", at: \.metadata)
    }
    
    Type(Page<Post>.self) {
        Field("items", at: \.items)
        Field("metadata", at: \.metadata)
    }
    
    Type(Page<RegisteredUser>.self) {
        Field("items", at: \.items)
        Field("metadata", at: \.metadata)
    }
    
    Query {
        Field("self", at: Resolver.getSelf)
        Field("user", at: Resolver.getRegisteredUser) {
            Argument("id", at: \.id)
        }
        Field("posts", at: Resolver.getPostsByUser) {
            Argument("creator", at: \.creator)
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
        Field("post", at: Resolver.getPostById) {
            Argument("id", at: \.id)
        }
        Field("recentPosts", at: Resolver.getRecentPosts) {
            Argument("count", at: \.count)
            Argument("before", at: \.before)
        }
        Field("confessions", at: Resolver.getConfessions) {
            Argument("page", at: \.page)
            Argument("per", at: \.per)
        }
        Field("latestConfession", at: Resolver.getLatestConfession)
    }
    
    Mutation {
        Field("editProfile", at: Resolver.editProfile) {
            Argument("bio", at: \.bio)
            Argument("pronouns", at: \.pronouns)
        }
        Field("createPost", at: Resolver.createPost) {
            Argument("content", at: \.content)
        }
        Field("archivePost", at: Resolver.archivePost) {
            Argument("id", at: \.id)
        }
        Field("deletePost", at: Resolver.deletePost) {
            Argument("id", at: \.id)
        }
        Field("restorePost", at: Resolver.restorePost) {
            Argument("id", at: \.id)
        }
        Field("replyToPost", at: Resolver.replyToPost) {
            Argument("to", at: \.to)
            Argument("content", at: \.content)
        }
        Field("likePost", at: Resolver.likePost) {
            Argument("id", at: \.id)
        }
        Field("unlikePost", at: Resolver.unlikePost) {
            Argument("id", at: \.id)
        }
        Field("followUser", at : Resolver.followUser) {
            Argument("id", at: \.id)
        }
        Field("unfollowUser", at: Resolver.unfollowUser) {
            Argument("id", at: \.id)
        }
        Field("confess", at: Resolver.confess) {
            Argument("content", at: \.content)
        }
        Field("likeConfession", at: Resolver.likeConfession) {
            Argument("id", at: \.id)
        }
        Field("unlikeConfession", at: Resolver.unlikeConfession) {
            Argument("id", at: \.id)
        }
    }
}
