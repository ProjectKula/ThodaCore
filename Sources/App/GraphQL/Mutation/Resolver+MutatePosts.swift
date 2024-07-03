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
    var attachments: [String]?
}

struct ReplyToPostArgs: Codable {
    var to: String
    var content: String
    var attachments: [String]?
}

struct LikePostArgs: Codable {
    var post: String
}

extension Resolver {
    func newPost(post: Post, attachments: [String]?, on db: Database) async throws -> Post {
        if attachments != nil && attachments!.count > 8 {
            throw Abort(.badRequest, reason: "Too many attachments")
        }
        try await db.transaction { db in
            try await post.create(on: db)
            if let attachments = attachments {
                for attachment in attachments {
                    let attachment = Attachment(parent: try post.requireID(), hash: attachment)
                    try await attachment.create(on: db)
                }
            }
        }
        return post
    }
    
    // MARK: Creating posts
    func createPost(request: Request, arguments: CreatePostArgs) async throws -> Post {
        try await assertScope(request: request, .createPosts)
        if arguments.attachments != nil && arguments.attachments!.count > 8 {
            throw Abort(.badRequest, reason: "Too many attachments")
        }
        let post = Post(userId: request.token.id, content: arguments.content)
        return try await newPost(post: post, attachments: arguments.attachments, on: request.db)
    }

    func replyToPost(request: Request, arguments: ReplyToPostArgs) async throws -> Post {
        try await assertScope(request: request, .createPosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.to).first()
          .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        let reply = Post(userId: request.token.id, content: arguments.content)
        reply.$reply.id = post.id
        return try await newPost(post: reply, attachments: arguments.attachments, on: request.db)
    }

    // MARK: Deleting posts
    func archivePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        try await assertScope(request: request, .deletePosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
          .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if request.token.id != post.$creator.id {
            request.logger.error("User \(request.token.id) tried to archive a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }

        try await post.delete(on: request.db)        
        return post
    }

    func deletePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        try await assertScope(request: request, .deletePosts)
        let post = try await Post.query(on: request.db).filter(\.$id == arguments.id).first()
          .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if request.token.id != post.$creator.id {
            request.logger.error("User \(request.token.id) tried to delete a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }

        try await post.delete(force: true, on: request.db)
        return post
    }
    
    func restorePost(request: Request, arguments: StringIdArgs) async throws -> Post {
        try await assertScope(request: request, .createPosts)
        let post = try await Post.query(on: request.db).withDeleted().filter(\.$id == arguments.id).first()
          .unwrap(orError: Abort(.notFound, reason: "Could not find post with given ID")).get()
        
        if request.token.id != post.$creator.id {
            request.logger.error("User \(request.token.id) tried to restore a post by \(post.$creator.id)")
            throw Abort(.forbidden, reason: "Not post creator")
        }
        
        try await post.restore(on: request.db)
        return post
    }

    // MARK: Liking posts
    func likePost(request: Request, arguments: StringIdArgs) async throws -> Int {
        try await assertScope(request: request, .createPosts)
        let lp: LikedPost = .init(postId: arguments.id, userId: request.token.id)
        let post: Post? = try await Post.find(arguments.id, on: request.db)
        guard let post = post else {
            throw Abort(.notFound, reason: "Could not find post with given ID")
        }            
        try await lp.create(on: request.db)
        let notif: Notification = .like(target: post.$creator.id, user: request.token.id, post: arguments.id)
        try await notif.create(on: request.db)
        return try await LikedPost.query(on: request.db).filter(\.$post.$id == arguments.id).count().get()
    }
    
    func unlikePost(request: Request, arguments: StringIdArgs) async throws -> Int {
        try await assertScope(request: request, .createPosts)
        let lp = try await LikedPost.query(on: request.db)
          .filter(\.$post.$id == arguments.id)
          .filter(\.$user.$id == request.token.id)
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
