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
            throw Abort(.badRequest, reason: "Invalid credentials")
        }
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}
