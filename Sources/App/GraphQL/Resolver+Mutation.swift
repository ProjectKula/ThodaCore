//
//  File.swift
//  
//
//  Created by Shrish Deshpande on 05/01/24.
//

import Vapor
import Graphiti
import Fluent

struct EditProfileArgs: Codable {
    var gender: String?
    var bio: String?
    var pronouns: String?
    var personalEmail: String?
}

struct CreatePostArgs: Codable {
    var content: String
}

struct LikePostArgs: Codable {
    var post: String
}

extension Resolver {
    func editProfile(request: Request, arguments: EditProfileArgs) async throws -> RegisteredUser {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .editProfile)
        
        guard let user = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == token.id)
            .first() else {
            throw Abort(.notFound, reason: "User \(token.id) not found")
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
        try await assertScope(request: request, .createPosts)
        let post = Post(userId: token.id, content: arguments.content)
        try await post.create(on: request.db)
        return post
    }
    
    func deletePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .deletePosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if token.id != post.$creator.id {
            request.logger.error("User \(token.id) tried to delete a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }
        
        post.deleted = true
        try await post.update(on: request.db)
        return post
    }
    
    func restorePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .deletePosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if token.id != post.$creator.id {
            request.logger.error("User \(token.id) tried to restore a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }
        
        post.deleted = false
        try await post.update(on: request.db)
        return post
    }
    
    func likePost(request: Request, arguments: LikePostArgs) async throws -> LikedPost {
        try await assertScope(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        let lp: LikedPost = .init(postId: arguments.post, userId: token.id)
        try await lp.create(on: request.db)
        return lp
    }
    
    func unlikePost(request: Request, arguments: LikePostArgs) async throws -> LikedPost {
        try await assertScope(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        let lp = try await LikedPost.query(on: request.db)
            .filter(\.$post.$id == arguments.post)
            .filter(\.$user.$id == token.id)
            .first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID"))
            .get()
        try await lp.delete(on: request.db)
        return lp
    }
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
