//
//  File.swift
//  
//
//  Created by Shrish Deshpande on 05/01/24.
//

import Vapor
import Graphiti
import Fluent

struct EditUserInfoArgs: Codable {
    var id: Int?
    var gender: String?
    var bio: String?
    var pronouns: String?
    var personalEmail: String?
}

struct CreatePostArgs: Codable {
    var creator: Int?
    var content: String
}

extension Resolver {
    func editUserInfo(request: Request, arguments: EditUserInfoArgs) async throws -> RegisteredUser {
        let token = try await getAndVerifyAccessToken(req: request)
        
        let userId: Int
        
        if let user = arguments.id {
            if token.id == arguments.id {
                try await assertPermission(request: request, .editProfile)
            } else if (!token.perm.hasPermission(.admin)) {
                request.logger.error("User \(token.id) tried to edit user info of \(user)")
                throw Abort(.forbidden, reason: "Mismatch in registration number")
            }
            userId = user
        } else {
            userId = token.id
        }
        
        guard let user = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "User \(userId) not found")
        }
        
        user.setValue(\.gender, arguments.gender, orElse: "X")
        user.setValue(\.bio, arguments.bio, orElse: nil)
        user.setValue(\.pronouns, arguments.pronouns, orElse: nil)
        user.setValue(\.personalEmail, arguments.personalEmail, orElse: nil)
        
        try await user.update(on: request.db)
        
        return user
    }
    
    func createPost(request: Request, arguments: CreatePostArgs) async throws -> Post {
        let token = try await getAndVerifyAccessToken(req: request)
        
        let creatorId: Int
        
        if let creator = arguments.creator {
            if token.id == arguments.creator {
                try await assertPermission(request: request, .editProfile)
            } else if (!token.perm.hasPermission(.admin)) {
                request.logger.error("User \(token.id) tried to create a post by \(creator)")
                throw Abort(.forbidden, reason: "Mismatch in registration number")
            }
            creatorId = creator
        } else {
            creatorId = token.id
        }
        
        let post = Post(userId: creatorId, content: arguments.content)
        try await post.create(on: request.db)
        return post
    }
}

extension RegisteredUser {
    func setValue(_ path: ReferenceWritableKeyPath<RegisteredUser, String?>, _ val: String?, orElse: String?) {
        if let new = val {
            self[keyPath: path] = new.isEmpty ? orElse : new
        }
    }
    
    func setValue(_ path: ReferenceWritableKeyPath<RegisteredUser, String>, _ val: String?, orElse: String) {
        if let new = val {
            self[keyPath: path] = new.isEmpty ? orElse : new
        }
    }
}
