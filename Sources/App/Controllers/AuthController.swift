//
//  AuthController.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        auth.group("pw") { e in
            e.post(use: initialAuth)
            e.get(use: methodNotAllowed)
        }
    }
    
    func initialAuth(req: Request) async throws -> AuthResponseBody {
        let params: AuthRequest
        do {
            params = try req.content.decode(AuthRequest.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        throw Abort(.notImplemented, reason: "we have no users yet \(params.id)")
    }
    
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}

struct AuthRequest: Content {
    let id: String
    let pw: String
}

struct AuthResponseBody: Content {
    let accessToken: String
    let refreshToken: String
}
