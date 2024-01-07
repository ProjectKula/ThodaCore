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
    let before: Date?
}

extension Resolver {
    func getPostsByUser(request: Request, arguments: IntIdArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        return try await Post.query(on: request.db)
            .filter(\.$creator.$id == arguments.id)
            .all()
    }
    
    func getPostById(request: Request, arguments: StringIdArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        return try await Post.query(on: request.db)
            .filter(\.$id == arguments.id)
            .all()
    }
    
    func getRecentPosts(request: Request, arguments: RecentPostsArgs) async throws -> [Post] {
        try await assertPermission(request: request, .read)
        
        return try await Post.query(on: request.db)
            .filter(\.$deleted == false)
            .filter(\.$createdAt < (arguments.before ?? Date.now))
            .sort(\.$createdAt, .descending)
            .limit(arguments.count)
            .all()
    }
}
