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

struct PostsPaginationArgs: Codable {
    var creator: Int
    var page: Int
    var per: Int
}

extension Resolver {
    func getPostsByUser(request: Request, arguments: PostsPaginationArgs) async throws -> Page<Post> {
        return try await Post.query(on: request.db)
            .filter(\.$creator.$id == arguments.creator)
            .sort(\.$createdAt, .descending)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }
    
    func getPostById(request: Request, arguments: StringIdArgs) async throws -> Post {
        return try await Post.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first()
            .unwrap(or: Abort(.notFound))
            .get()
    }
    
    func getRecentPosts(request: Request, arguments: RecentPostsArgs) async throws -> [Post] {
        let before = arguments.beforeDate ?? Date.now

        return try await Post.query(on: request.db)
            .filter(\.$createdAt < before)
            .sort(\.$createdAt, .descending)
            .limit(min(arguments.count, 10))
            .all()
    }
}
