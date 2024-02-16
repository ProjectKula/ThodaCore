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
//    func getAllRegisteredUsers(request: Request, arguments: NoArguments) async throws -> [RegisteredUser] {
//        try await assertScope(request: request, [.query, .read])
//        return try await RegisteredUser.query(on: request.db).all()
//    }
    
    func getRegisteredUser(request: Request, arguments: IntIdArgs) async throws -> RegisteredUser {
        try await assertScope(request: request, .read)
        let user = try await getContextUser(request)
        if !(try await checkScope(request: request, .identity)) {
            user.personalEmail = nil
            user.phone = ""
        }
        return user
    }
    
    func getSelf(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await getContextUser(request)
    }
                              
    func getContextUser(_ request: Request) async throws -> RegisteredUser {
        let token = try await getAndVerifyAccessToken(req: request)
        return try await RegisteredUser.query(on: request.db)
            .filter(\.$id == token.id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "Context user \(token.id) not found"))
            .get()
    }
}
