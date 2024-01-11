//
//  Resolver+GetPosts.swift
//
//
//  Created by Shrish Deshpande on 07/01/24.
//

import Graphiti
import Fluent
import Vapor

struct RecentPostsArgs: Codable {
    let count: Int
    let before: Int? // Unix milliseconds
    let likes: Bool?
    let creator: Bool?
    
    var beforeDate: Date? {
        guard let before = self.before else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(before))
    }
    
    var hasLikes: Bool {
        self.likes ?? false
    }
    
    var hasCreator: Bool {
        self.creator ?? false
    }
}

struct PostByIdArgs: Codable {
    let id: String
    let likes: Bool?
    let creator: Bool?
    
    var hasLikes: Bool {
        self.likes ?? false
    }
    
    var hasCreator: Bool {
        self.creator ?? false
    }
}

struct PostByUserArgs: Codable {
    let id: Int
    let likes: Bool?
    
    var hasLikes: Bool {
        self.likes ?? false
    }
}

extension Resolver {
    func getPostsByUser(request: Request, arguments: PostByUserArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        return try await Post.query(on: request.db)
            .with(\.$creator)
            .filter(\.$creator.$id == arguments.id)
            .all()
    }
    
    func getPostById(request: Request, arguments: PostByIdArgs) async throws -> Post {
        try await assertPermission(request: request, .read)
        var query: QueryBuilder<Post> = Post.query(on: request.db)
        query = arguments.hasLikes ? query.with(\.$likes) : query
        query = arguments.hasCreator ? query.with(\.$creator) : query
        return try await query
            .filter(\.$id == arguments.id)
            .first()
            .unwrap(or: Abort(.notFound))
            .get()
    }
    
    func getRecentPosts(request: Request, arguments: RecentPostsArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        
        var query: QueryBuilder<Post> = Post.query(on: request.db)
        query = arguments.hasLikes ? query.with(\.$likes) : query
        query = arguments.hasCreator ? query.with(\.$creator) : query
        let before = arguments.beforeDate ?? Date.now
        
        return try await query
            .filter(\.$deleted == false)
            .filter(\.$createdAt < before)
            .sort(\.$createdAt, .descending)
            .limit(min(arguments.count, 10))
            .all()
    }
}
