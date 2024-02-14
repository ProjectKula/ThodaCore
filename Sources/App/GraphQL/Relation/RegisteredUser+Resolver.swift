//
//  RegisteredUser+Resolver.swift
//
//
//  Created by Shrish Deshpande on 14/02/24.
//

import Fluent
import Vapor
import Graphiti

// TODO: use a data loader (these are N+1 queries)
extension RegisteredUser {
    // TODO: use pagination
    func getPosts(request: Request, arguments: NoArguments) async throws -> [Post] {
        return try await self.$posts.query(on: request.db).all()
    }
    
    // TODO: use pagination
    func getLikedPosts(request: Request, arguments: NoArguments) async throws -> [Post] {
        return try await self.$likedPosts.query(on: request.db).all()
    }
}
