//
//  Resolver+MutateUser.swift
//
//
//  Created by Shrish Deshpande on 16/02/24.
//

import Vapor
import Graphiti
import Fluent

struct EditProfileArgs: Codable {
    var bio: String?
    var pronouns: String?
}

extension Resolver {
    func editProfile(request: Request, arguments: EditProfileArgs) async throws -> RegisteredUser {
        try await assertScope(request: request, .editProfile)
        
        let user = try await getContextUser(request)
        
        user.setValue(\.bio, arguments.bio, orElse: nil)
        user.setValue(\.pronouns, arguments.pronouns, orElse: nil)
        
        try await user.update(on: request.db)
        
        return user
    }
    
    func followUser(request: Request, arguments: IntIdArgs) async throws -> Int {
        try await assertScope(request: request, .followUsers)
        
        let user = try await getContextUser(request)
        
        guard let target = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first() else {
            throw Abort(.notFound, reason: "User \(arguments.id) not found")
        }

        let notif: Notification = .follow(targetUser: try target.requireID(), referenceUser: try user.requireID())
        try await notif.create(on: request.db)
        
        try await user.$following.attach(target, on: request.db)
        
        return try await target.$following.query(on: request.db).count()
    }
    
    func unfollowUser(request: Request, arguments: IntIdArgs) async throws -> Int {
        try await assertScope(request: request, .followUsers)
        
        let user = try await getContextUser(request)
        
        let target = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User \(arguments.id) not found"))
            .get()
        
        try await user.$following.detach(target, on: request.db)
        
        return try await target.$following.query(on: request.db).count()
    }
}
