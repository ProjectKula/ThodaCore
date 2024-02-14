//
//  Post+GraphQL.swift
//
//
//  Created by Shrish Deshpande on 14/02/24.
//

import Fluent
import Vapor
import Graphiti

// TODO: use a data loader (these are N+1 queries)
extension Post {
    func getLikesCount(request: Request, arguments: NoArguments) async throws -> Int {
        return try await self.$likes.query(on: request.db).count()
    }
    
    func getCreator(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await self.$creator.get(on: request.db)
    }
    
    // TODO: use pagination
    func getLikes(request: Request, arguments: NoArguments) async throws -> [LikedPost] {
        return try await self.$likes.query(on: request.db).all()
    }
}
