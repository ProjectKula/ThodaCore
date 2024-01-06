//
//  File.swift
//  
//
//  Created by Shrish Deshpande on 05/01/24.
//

import Vapor
import Graphiti
import Fluent

struct EditUserInfoArgs: Codable {
    var id: Int?
    var gender: String?
    var bio: String?
    var pronouns: String?
    var personalEmail: String?
}

struct CreatePostArgs: Codable {
    var creator: Int?
    var content: String
}

struct LikePostArgs: Codable {
    var user: Int?
    var post: String
}

extension Resolver {
    func editUserInfo(request: Request, arguments: EditUserInfoArgs) async throws -> RegisteredUser {
        let token = try await getAndVerifyAccessToken(req: request)
        
        let userId: Int
        
        if let user = arguments.id {
            if token.id == arguments.id {
                try await assertPermission(request: request, .editProfile)
            } else if (!token.perm.hasPermission(.admin)) {
                request.logger.error("User \(token.id) tried to edit user info of \(user)")
                throw Abort(.forbidden, reason: "Mismatch in registration number")
            }
            userId = user
        } else {
            userId = token.id
        }
        
        guard let user = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "User \(userId) not found")
        }
        
        user.setValue(\.gender, arguments.gender, orElse: "X")
        user.setValue(\.bio, arguments.bio, orElse: nil)
        user.setValue(\.pronouns, arguments.pronouns, orElse: nil)
        user.setValue(\.personalEmail, arguments.personalEmail, orElse: nil)
        
        try await user.update(on: request.db)
        
        return user
    }
    
    func createPost(request: Request, arguments: CreatePostArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        
        let creatorId: Int
        
        if let creator = arguments.creator {
            if token.id == arguments.creator {
                try await assertPermission(request: request, .createPosts)
            } else if (!token.perm.hasPermission(.admin)) {
                request.logger.error("User \(token.id) tried to create a post by \(creator)")
                throw Abort(.forbidden, reason: "Mismatch in registration number")
            }
            creatorId = creator
        } else {
            creatorId = token.id
        }
        
        let post = Post(userId: creatorId, content: arguments.content)
        try await post.create(on: request.db)
        return post
    }
    
    func deletePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if token.id == post.$creator.id {
            try await assertPermission(request: request, .deletePosts)
        } else if (!token.perm.hasPermission(.admin)) {
            request.logger.error("User \(token.id) tried to delete a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }
        
        post.deleted = true
        try await post.update(on: request.db)
        return post
    }
    
    func restorePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if token.id == post.$creator.id {
            try await assertPermission(request: request, .deletePosts)
        } else if (!token.perm.hasPermission(.admin)) {
            request.logger.error("User \(token.id) tried to restore a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }
        
        post.deleted = false
        try await post.update(on: request.db)
        return post
    }
    
    func likePost(request: Request, arguments: LikePostArgs) async throws -> LikedPost {
        try await assertPermission(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        if arguments.user != token.id {
            try await assertPermission(request: request, .admin)
        }
        let lp: LikedPost = .init(postId: arguments.post, userId: arguments.user ?? token.id)
        try await lp.create(on: request.db)
        return lp
    }
    
//    func unlikePost(request: Request, arguments: LikePostArgs) async throws -> LikedPost {
//        try await assertPermission(request: request, .createPosts)
//        let token = try await getAndVerifyAccessToken(req: request)
//        if arguments.user != token.id {
//            try await assertPermission(request: request, .admin)
//        }
//        let lp = LikedPost.
//        try await lp.delete(on: request.db)
//        return lp
//    }
}

extension RegisteredUser {
    func setValue(_ path: ReferenceWritableKeyPath<RegisteredUser, String?>, _ val: String?, orElse: String?) {
        if let new = val {
            self[keyPath: path] = new.isEmpty ? orElse : new
        }
    }
    
    func setValue(_ path: ReferenceWritableKeyPath<RegisteredUser, String>, _ val: String?, orElse: String) {
        if let new = val {
            self[keyPath: path] = new.isEmpty ? orElse : new
        }
    }
}
