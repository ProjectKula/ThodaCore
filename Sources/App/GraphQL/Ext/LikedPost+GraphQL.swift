//
//  LikedPost+GraphQL.swift
//
//
//  Created by Shrish Deshpande on 14/02/24.
//

import Fluent
import Vapor
import Graphiti

// TODO: use a data loader (these are N+1 queries)
extension LikedPost {
    func getPost(request: Request, arguments: NoArguments) async throws -> Post {
        return try await self.$post.get(on: request.db)
    }
    
    func getUser(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await self.$user.get(on: request.db)
    }
}
