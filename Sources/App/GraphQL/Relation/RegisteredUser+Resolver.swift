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
    func getPosts(request: Request, arguments: PaginationArgs) async throws -> Page<Post> {
        return try await self.$posts.query(on: request.db)
            .sort(\.$id)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }
    
    func getLikedPosts(request: Request, arguments: PaginationArgs) async throws -> Page<Post> {
        return try await self.$likedPosts.query(on: request.db)
            .sort(\.$id)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }
    
    func isSelf(request: Request, arguments: NoArguments) async throws -> Bool {
        return try await getAndVerifyAccessToken(req: request).id == self.id
    }
    
    func getFollowers(request: Request, arguments: PaginationArgs) async throws -> Page<RegisteredUser> {
        return try await self.$followers.query(on: request.db)
            .sort(\.$id)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }
    
    func getFollowerCount(request: Request, arguments: NoArguments) async throws -> Int {
        return try await self.$followers.query(on: request.db).count()
    }
    
    func getFollowing(request: Request, arguments: PaginationArgs) async throws -> Page<RegisteredUser> {
        return try await self.$following.query(on: request.db)
            .sort(\.$id)
            .paginate(.init(page: arguments.page, per: arguments.per))
    }
    
    func getFollowingCount(request: Request, arguments: NoArguments) async throws -> Int {
        return try await self.$following.query(on: request.db).count()
    }
    
    // self refers to the context user, not the user being resolved
    func followsSelf(request: Request, arguments: NoArguments) async throws -> Bool {
        let token = try await getAndVerifyAccessToken(req: request)
        return try await self.$following.isAttached(toID: token.id, on: request.db)
    }
    
    func followedBySelf(request: Request, arguments: NoArguments) async throws -> Bool {
        let token = try await getAndVerifyAccessToken(req: request)
        return try await self.$followers.isAttached(toID: token.id, on: request.db)
    }

    func getNotifications(request: Request, arguments: NoArguments) async throws -> [Notification] {
        let token = try await getAndVerifyAccessToken(req: request)
        if token.id != self.id {
            throw Abort(.forbidden)
        }
        return try await self.$notifications.query(on: request.db).all()
    }

    func getBadges(request: Request, arguments: NoArguments) async throws -> [Badge] {
        return try await self.$badges.query(on: request.db).all()
    }
}
