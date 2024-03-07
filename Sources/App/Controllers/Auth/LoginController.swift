//
//  LoginController.swift
//
//
//  Created by Shrish Deshpande on 14/12/23.
//

import Vapor
import Fluent

struct LoginController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0").grouped("auth").grouped("login")
        
        e.post("email", use: authWithEmail)
        e.get("email", use: methodNotAllowed)
        
        e.post("id", use: authWithId)
        e.get("id", use: methodNotAllowed)
    }
    
    func authWithEmail(req: Request) async throws -> AuthResponseBody {
        let args: EmailLoginArgs
        
        do {
            args = try req.content.decode(EmailLoginArgs.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        return try await UserPassword.query(on: req.db)
            .join(RegisteredUser.self, on: \UserPassword.$id == \RegisteredUser.$id)
            .filter(RegisteredUser.self, \.$email == args.email)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User does not exist"))
            .get()
            .auth(req: req, args: args)
    }
    
    func authWithId(req: Request) async throws -> AuthResponseBody {
        let args: CollegeIdLoginArgs
        
        do {
            args = try req.content.decode(CollegeIdLoginArgs.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        return try await UserPassword.query(on: req.db)
            .join(RegisteredUser.self, on: \UserPassword.$id == \RegisteredUser.$id)
            .filter(RegisteredUser.self, \RegisteredUser.$collegeId.$id == args.collegeId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User does not exist"))
            .get()
            .auth(req: req, args: args)
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}

struct EmailLoginArgs: Content, PasswordProvider {
    var email: String
    var password: String
}

struct CollegeIdLoginArgs: Content, PasswordProvider {
    var collegeId: String
    var password: String
}
