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
    
    var beforeDate: Date? {
        guard let before = self.before else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(before))
    }
    
    var hasLikes: Bool {
        self.likes ?? false
    }
}

struct PostByIdArgs: Codable {
    let id: String
    let likes: Bool?
    
    var hasLikes: Bool {
        self.likes ?? false
    }
}

extension Resolver {
    func getPostsByUser(request: Request, arguments: IntIdArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        return try await Post.query(on: request.db)
            .filter(\.$creator.$id == arguments.id)
            .all()
    }
    
    func getPostById(request: Request, arguments: PostByIdArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        let query: QueryBuilder<Post> = arguments.hasLikes ? Post.query(on: request.db).with(\.$likes) : Post.query(on: request.db)
        return try await query
            .filter(\.$id == arguments.id)
            .all()
    }
    
    func getRecentPosts(request: Request, arguments: RecentPostsArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        
        let query: QueryBuilder<Post> = arguments.hasLikes ? Post.query(on: request.db).with(\.$likes) : Post.query(on: request.db)
        let before = arguments.beforeDate ?? Date.now
        
        return try await query
            .filter(\.$deleted == false)
            .filter(\.$createdAt < before)
            .sort(\.$createdAt, .descending)
            .limit(min(arguments.count, 10))
            .all()
    }
}
