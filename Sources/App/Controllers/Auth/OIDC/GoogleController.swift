//
//  GoogleController.swift
//
//
//  Created by Shrish Deshpande on 28/12/23.
//

import Vapor
import JWTKit
import Fluent

struct GoogleController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0").grouped("auth").grouped("google")
        
        e.post(use: verifyGoogleCredentials)
        e.get(use: methodNotAllowed)
        
        e.group("link") { f in
            f.post(use: linkGoogleAccount)
            f.get(use: methodNotAllowed)
        }
    }
    
    func verifyGoogleCredentials(req: Request) async throws -> AuthResponseBody {
        let token: GoogleIdentityToken = try await req.jwt.google.verify()
        let openId = token.subject.value
        
        if let oidc = try await UserOIDC.query(on: req.db)
            .filter(\.$idp == .google)
            .filter(\.$openId == openId)
            .first()
            .get() {
            return try await oidc.authUser(req: req)
        }
        
        // The user does not have their google account linked
        guard let email = token.email else {
            throw Abort(.badRequest, reason: "Missing email in identity token")
        }
        
        if token.hostedDomain?.value == appConfig.external.googleWorkspaceDomain {
            var user = try await RegisteredUser.query(on: req.db)
                .filter(\.$email == email)
                .first()
                .get()
            
            if user == nil {
                // The user does not exist yet
                let unregUser: UnregisteredUser = try await UnregisteredUser.query(on: req.db)
                    .filter(\.$email == email)
                    .first()
                    .unwrap(orError: Abort(.notFound, reason: "User not found"))
                    .get()
                let registeredUser: InitialRegisteredUser = try .init(user: unregUser)
                try await registeredUser.create(on: req.db)
                user = try await RegisteredUser.query(on: req.db)
                    .filter(\.$email == email)
                    .first()
                    .unwrap(or: Abort(.internalServerError, reason: "Tried to retrieve user but failed"))
                    .get()
            }
            
            guard let user = user else {
                throw Abort(.internalServerError, reason: "User not found")
            }
            
            let oidc: UserOIDC = .init(user: user, idp: .google, openId: openId, email: user.email)
            try await oidc.create(on: req.db)
            return try await oidc.authUser(req: req)
        }

        throw Abort(.forbidden, reason: "Google account is not linked to any user")
    }
    
    func linkGoogleAccount(req: Request) async throws -> LinkSuccess {
        let token = try await req.jwt.google.verify()
        
        guard let idTokenString = req.body.string else {
            throw Abort(.badRequest, reason: "Please provide the access token")
        }
        
        let identityToken = try req.jwt.verify(idTokenString, as: IdentityToken.self)
        
        let user = try await RegisteredUser.query(on: req.db)
            .filter(\.$id == identityToken.id)
            .first()
            .unwrap(orError: Abort(.notFound, reason: "User not registered"))
            .get()
        
        let oidc: UserOIDC = .init(user: user, idp: .google, openId: token.subject.value, email: token.email)
        try await oidc.create(on: req.db)
        return .init(success: true)
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}

struct LinkSuccess: Content {
    let success: Bool
}
