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

struct ReplyToPostArgs: Codable {
    var to: String
    var content: String
}

struct LikePostArgs: Codable {
    var post: String
}

extension Resolver {
    // MARK: Creating posts
    func createPost(request: Request, arguments: CreatePostArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .createPosts)
        let post = Post(userId: token.id, content: arguments.content)
        try await post.create(on: request.db)
        return post
    }

    func replyToPost(request: Request, arguments: ReplyToPostArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .createPosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.to).first()
          .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        let reply = Post(userId: token.id, content: arguments.content)
        reply.$reply.id = post.id
        try await reply.create(on: request.db)
        return reply
    }

    // MARK: Deleting posts
    func archivePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .deletePosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
          .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if token.id != post.$creator.id {
            request.logger.error("User \(token.id) tried to archive a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }

        try await post.delete(on: request.db)        
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

        try await post.delete(force: true, on: request.db)
        return post
    }
    
    func restorePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .createPosts)
        let post = try await Post.query(on: request.db).withDeleted().filter(\.$id == arguments.id).first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if token.id != post.$creator.id {
            request.logger.error("User \(token.id) tried to restore a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }
        
        try await post.restore(on: request.db)
        return post
    }

    // MARK: Liking posts
    func likePost(request: Request, arguments: StringIdArgs) async throws -> Int {
        try await assertScope(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        let lp: LikedPost = .init(postId: arguments.id, userId: token.id)
        try await lp.create(on: request.db)
        return try await LikedPost.query(on: request.db).filter(\.$post.$id == arguments.id).count().get()
    }
    
    func unlikePost(request: Request, arguments: StringIdArgs) async throws -> Int {
        try await assertScope(request: request, .createPosts)
        let token = try await getAndVerifyAccessToken(req: request)
        let lp = try await LikedPost.query(on: request.db)
            .filter(\.$post.$id == arguments.id)
            .filter(\.$user.$id == token.id)
            .first()
            .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID"))
            .get()
        try await lp.delete(on: request.db)
        return try await LikedPost.query(on: request.db).filter(\.$post.$id == arguments.id).count().get()
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
