//
//  LoginController.swift
//
//
//  Created by Shrish Deshpande on 14/12/23.
//

import Vapor

struct LoginController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("auth").grouped("login")
        
        e.post(use: initialAuth)
        e.get(use: methodNotAllowed)
    }
    
    func initialAuth(req: Request) async throws -> AuthResponseBody {
        let params: LoginAuthRequest
        
        do {
            params = try req.content.decode(LoginAuthRequest.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        if try await authUserWithPassword(req: req, args: params) {
            return try await generateTokenPairResponse(req: req, collegeId: params.id)
        } else {
            req.logger.warning("User '\(params.id)' tried to login with invalid credentials")
            throw Abort(.notFound, reason: "Invalid id \(params.id)")
        }
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}
