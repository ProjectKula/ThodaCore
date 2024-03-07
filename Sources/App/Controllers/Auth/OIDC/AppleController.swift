//
//  AppleController.swift
//
//
//  Created by Shrish Deshpande on 07/03/24.
//

import Vapor
import JWTKit
import Fluent

// it costs $99 to test this ;)
struct AppleController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0").grouped("auth").grouped("apple")
        
        e.post(use: authWithAppleId)
        e.get(use: methodNotAllowed)
        
        e.group("link") { f in
            f.post(use: linkAppleId)
            f.get(use: methodNotAllowed)
        }
    }
    
    func authWithAppleId(req: Request) async throws -> AuthResponseBody {
        let token: AppleIdentityToken = try await req.jwt.apple.verify()
        let openId = token.subject.value
        
        if let oidc = try await UserOIDC.query(on: req.db)
            .filter(\.$idp == .apple)
            .filter(\.$openId == openId)
            .first()
            .get() {
            return try await oidc.authUser(req: req)
        }

        throw Abort(.forbidden, reason: "Apple ID is not linked to any user")
    }
    
    func linkAppleId(req: Request) async throws -> LinkSuccess {
        let token: AppleIdentityToken = try await req.jwt.apple.verify()

        
        guard let idTokenString = req.body.string else {
            throw Abort(.badRequest, reason: "Please provide the access token")
        }
        
        let identityToken = try req.jwt.verify(idTokenString, as: IdentityToken.self)
        
        let user = try await RegisteredUser.query(on: req.db)
            .filter(\.$id == identityToken.id)
            .first()
            .unwrap(orError: Abort(.notFound, reason: "User not registered"))
            .get()
        
        let oidc: UserOIDC = .init(user: user, idp: .apple, openId: token.subject.value, email: token.email)
        try await oidc.create(on: req.db)
        return .init(success: true)
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}
