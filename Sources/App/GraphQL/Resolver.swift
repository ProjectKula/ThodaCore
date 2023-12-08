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

struct GetUserArgs: Codable {
    let id: String
    let email: String
}

final class Resolver {
    func getAllUsers(request: Request, arguments: NoArguments) throws -> EventLoopFuture<[User]> {
        User.query(on: request.db).all()
    }
    
    func getAllRegisteredUsers(request: Request, arguments: NoArguments) throws -> EventLoopFuture<[RegisteredUser]> {
        RegisteredUser.query(on: request.db).all()
    }
    
    func getUser(request: Request, arguments: GetUserArgs) throws -> EventLoopFuture<User> {
        User.query(on: request.db)
            .filter(\.$id == arguments.id)
            .filter(\.$email == arguments.email)
            .first().unwrap(or: Abort(.notFound))
    }
    
    func getRegisteredUser(request: Request, arguments: GetRegisteredUserArgs) throws -> EventLoopFuture<RegisteredUser> {
        RegisteredUser.query(on: request.db)
            .filter(\.$id == arguments.id)
            .first().unwrap(or: Abort(.notFound))
    }
}
