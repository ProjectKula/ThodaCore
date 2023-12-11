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
    let id: String
}

final class Resolver {
    static let instance: Resolver = .init()
    
    func getAllUsers(request: Request, arguments: NoArguments) throws -> EventLoopFuture<[UnregisteredUser]> {
        UnregisteredUser.query(on: request.db).all()
    }
    
    func getAllRegisteredUsers(request: Request, arguments: NoArguments) throws -> EventLoopFuture<[RegisteredUser]> {
        RegisteredUser.query(on: request.db).all()
    }
    
    func getUser(request: Request, arguments: GetUserArgs) throws -> EventLoopFuture<UnregisteredUser> {
        UnregisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .filter(\.$email == arguments.email)
            .first().unwrap(or: Abort(.notFound, reason: "User does not exist"))
    }
    
    func getRegisteredUser(request: Request, arguments: GetRegisteredUserArgs) throws -> EventLoopFuture<RegisteredUser> {
        RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first().unwrap(or: Abort(.notFound))
    }
}
