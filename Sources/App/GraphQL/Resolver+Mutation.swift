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
    var id: Int
    var gender: String?
    var bio: String?
    var pronouns: String?
    var personalEmail: String?
}

extension Resolver {
    func editUserInfo(request: Request, arguments: EditUserInfoArgs) async throws -> RegisteredUser {
        let token = try await getAndVerifyAccessToken(req: request)
        
        if token.id == arguments.id {
            try await assertPermission(request: request, .editProfile)
        } else if (!token.perm.hasPermission(.admin)) {
            request.logger.error("User \(token.id) tried to edit user info of \(arguments.id)")
            throw Abort(.forbidden, reason: "Mismatch in registration number")
        }
        
        guard let user = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first() else {
            throw Abort(.notFound, reason: "User \(arguments.id) not found")
        }
        
        user.setValue(\.gender, arguments.gender, orElse: "X")
        user.setValue(\.bio, arguments.bio, orElse: nil)
        user.setValue(\.pronouns, arguments.pronouns, orElse: nil)
        user.setValue(\.personalEmail, arguments.personalEmail, orElse: nil)
        
        try await user.update(on: request.db)
        
        return user
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
