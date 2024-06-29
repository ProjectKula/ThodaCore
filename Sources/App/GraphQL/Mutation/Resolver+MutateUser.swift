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
        
        do {
            try await user.update(on: request.db)
        } catch {
            request.logger.error("Error updating user profile: \(String(reflecting: error))")
            throw Abort(.internalServerError, reason: "Error updating user profile")
        }
        
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

        do {
            try await request.db.transaction { db in
                try await notif.create(on: db)
                try await user.$following.attach(target, on: db)   
            }
        } catch {
            request.logger.error("Error following user: \(String(reflecting: error))")
            throw Abort(.internalServerError, reason: "Error following user")
        }
        
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
        
        do {
            try await user.$following.detach(target, on: request.db)
        } catch {
            request.logger.error("Error unfollowing user: \(String(reflecting: error))")
            throw Abort(.internalServerError, reason: "Error unfollowing user")
        }
        
        return try await target.$following.query(on: request.db).count()
    }
}
