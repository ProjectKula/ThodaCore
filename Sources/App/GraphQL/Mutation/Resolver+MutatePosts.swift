//
//  Resolver+MutatePosts.swift
//
//
//  Created by Shrish Deshpande on 16/02/24.
//

import Vapor
import Graphiti
import Fluent

struct CreatePostArgs: Codable {
    var content: String
}

struct LikePostArgs: Codable {
    var post: String
}

extension Resolver {    
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
    
    func likePost(request: Request, arguments: LikePostArgs) async throws -> Bool {
        try await assertScope(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        let lp: LikedPost = .init(postId: arguments.post, userId: token.id)
        try await lp.create(on: request.db)
        return true
    }
    
    func unlikePost(request: Request, arguments: LikePostArgs) async throws -> Bool {
        try await assertScope(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        let lp = try await LikedPost.query(on: request.db)
            .filter(\.$post.$id == arguments.post)
            .filter(\.$user.$id == token.id)
            .first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID"))
            .get()
        try await lp.delete(on: request.db)
        return true
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
