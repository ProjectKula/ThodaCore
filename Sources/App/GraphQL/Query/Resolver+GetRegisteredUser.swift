//
//  Resolver+GetRegisteredUser.swift
//
//
//  Created by Shrish Deshpande on 07/01/24.
//

import Graphiti
import Fluent
import Vapor

extension Resolver {
    func getAllRegisteredUsers(request: Request, arguments: NoArguments) async throws -> [RegisteredUser] {
        try await verifyAccessToken(req: request)
        return try await RegisteredUser.query(on: request.db).all()
    }
    
    func getRegisteredUser(request: Request, arguments: IntIdArgs) async throws -> RegisteredUser {
        let user = try await getContextUser(request)
        let target = try await RegisteredUser.find(arguments.id, on: request.db)
            .unwrap(or: Abort(.notFound, reason: "User \(arguments.id) not found"))
            .get()
        
        if (target.id != user.id) {
            target.personalEmail = nil
            target.phone = ""
        }
        
        return target
    }
    
    func getSelf(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await getContextUser(request)
    }
                        
    func getContextUser(_ request: Request) async throws -> RegisteredUser {
        let token = try await getAndVerifyAccessToken(req: request)
        return try await RegisteredUser.find(token.id, on: request.db)
            .unwrap(or: Abort(.notFound, reason: "Context user \(token.id) not found"))
            .get()
    }
}
