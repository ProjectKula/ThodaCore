//
//  Notification+Resolver.swift
//
//
//  Created by Shrish Deshpande on 24/06/24.
//

import Vapor
import Fluent
import Graphiti

extension Notification {
    func getTargetUser(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await self.$targetUser.get(on: request.db)
    }
    
    func getReferenceUser(request: Request, arguments: NoArguments) async throws -> RegisteredUser? {
        guard let refId = self.$referenceUser.id else {
            return nil
        }
        return try await request.loaders.users.load(key: refId, on: request.eventLoop)
    }

    func getReferencePost(request: Request, arguments: NoArguments) async throws -> Post? {
        return try await self.$referencePost.get(on: request.db)
    }
}
