//
//  Post+Resolver.swift
//
//
//  Created by Shrish Deshpande on 14/02/24.
//

import Fluent
import Vapor
import Graphiti

// TODO: data loader for the pagination things?
extension Post {
    func getLikesCount(request: Request, arguments: NoArguments) async throws -> Int {
        return try await request.loaders.postLikes.load(key: try self.requireID(), on: request.eventLoop)
    }
    
    func getCreator(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await request.loaders.users.load(key: self.$creator.id, on: request.eventLoop)
    }
    
    func getLikes(request: Request, arguments: PaginationArgs) async throws -> Page<RegisteredUser> {
        return try await self.$likes.query(on: request.db)
            .sort(\.$id)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }

    func getReplies(request: Request, arguments: PaginationArgs) async throws -> Page<Post> {
        return try await self.$replies.query(on: request.db)
            .sort(\.$createdAt, .descending)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }

    // TODO: data loader for this
    func selfLiked(request: Request, arguments: NoArguments) async throws -> Bool {
        return try await self.$likes.isAttached(toID: request.token.id, on: request.db)
    }

    func getAttachments(request: Request, arguments: NoArguments) async throws -> [String] {
        let id = try self.requireID()
        do {
            return try await request.loaders.attachments.load(key: try self.requireID(), on: request.eventLoop).map { $0.hash }
        } catch {
            request.logger.error("Failed to fetch attachments for post \(id): \(String(reflecting: error))")
            throw Abort(.internalServerError, reason: "Failed to fetch attachments")
        }
    }
}
