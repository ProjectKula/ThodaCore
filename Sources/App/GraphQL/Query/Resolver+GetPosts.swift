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
    
    var beforeDate: Date? {
        guard let before = self.before else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(before))
    }
}

extension Resolver {
    func getPostsByUser(request: Request, arguments: IntIdArgs) async throws -> [Post] {
        try await verifyAccessToken(req: request)
        return try await Post.query(on: request.db)
            .with(\.$creator)
            .filter(\.$creator.$id == arguments.id)
            .all()
    }
    
    func getPostById(request: Request, arguments: StringIdArgs) async throws -> Post {
        try await verifyAccessToken(req: request)
        return try await Post.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first()
            .unwrap(or: Abort(.notFound))
            .get()
    }
    
    func getRecentPosts(request: Request, arguments: RecentPostsArgs) async throws -> [Post] {
        try await verifyAccessToken(req: request)
        let before = arguments.beforeDate ?? Date.now

        return try await Post.query(on: request.db)
            .filter(\.$deleted == false)
            .filter(\.$createdAt < before)
            .sort(\.$createdAt, .descending)
            .limit(min(arguments.count, 10))
            .all()
    }
}
