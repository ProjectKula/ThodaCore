//
//  Post+Resolver.swift
//
//
//  Created by Shrish Deshpande on 14/02/24.
//

import Fluent
import Vapor
import Graphiti

// TODO: use a data loader (these are N+1 queries)
extension Post {
    // TODO: cache likes count
    func getLikesCount(request: Request, arguments: NoArguments) async throws -> Int {
        return try await self.$likes.query(on: request.db).count()
    }
    
    func getCreator(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await self.$creator.get(on: request.db)
    }
    
    func getLikes(request: Request, arguments: PaginationArgs) async throws -> Page<RegisteredUser> {
        return try await self.$likes.query(on: request.db)
            .sort(\.$id)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }
}
