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
    
    func isSelf(request: Request, arguments: NoArguments) async throws -> Bool {
        return try await getAndVerifyAccessToken(req: request).id == self.id
    }
    
    // TODO: use pagination
    func getFollowers(request: Request, arguments: NoArguments) async throws -> [RegisteredUser] {
        return try await self.$followers.query(on: request.db).all()
    }
    
    func getFollowerCount(request: Request, arguments: NoArguments) async throws -> Int {
        return try await self.$followers.query(on: request.db).count()
    }
    
    // TODO: use pagination
    func getFollowing(request: Request, arguments: NoArguments) async throws -> [RegisteredUser] {
        return try await self.$following.query(on: request.db).all()
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
}
