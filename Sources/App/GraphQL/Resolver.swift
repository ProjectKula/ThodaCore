//
//  Resolver.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Graphiti
import Fluent
import Vapor

struct GetRegisteredUserArgs: Codable {
    let id: Int
}

final class Resolver {
    static let instance: Resolver = .init()
    
    func getAllUsers(request: Request, arguments: NoArguments) async throws -> [UnregisteredUser] {
        try await assertPermission(request: request, .query)
        return try await UnregisteredUser.query(on: request.db).all()
    }
    
    func getAllRegisteredUsers(request: Request, arguments: NoArguments) async throws -> [RegisteredUser] {
        try await assertPermission(request: request, [.query, .identity])
        return try await RegisteredUser.query(on: request.db).all()
    }
    
    func getUser(request: Request, arguments: GetUserArgs) async throws -> UnregisteredUser {
        try await assertPermission(request: request, .query)
        return try await UnregisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .filter(\.$email == arguments.email)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User does not exist"))
            .get()
    }
    
    func getRegisteredUser(request: Request, arguments: GetRegisteredUserArgs) async throws -> RegisteredUser {
        try await assertPermission(request: request, .identity)
        return try await RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first()
            .unwrap(or: Abort(.notFound))
            .get()
    }
}
