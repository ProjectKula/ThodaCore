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
        try await assertPermission(request: request, [.query, .read])
        return try await RegisteredUser.query(on: request.db).all()
    }
    
    func getRegisteredUser(request: Request, arguments: IntIdArgs) async throws -> RegisteredUser {
        try await assertPermission(request: request, .read)
        let user = try await RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first()
            .unwrap(or: Abort(.notFound))
            .get()
        if !(try await checkPermission(request: request, .identity)) {
            user.personalEmail = nil
            user.phone = ""
        }
        return user
    }
}
