//
//  GoogleController.swift
//
//
//  Created by Shrish Deshpande on 28/12/23.
//

import Vapor
import AsyncHTTPClient
import JWTKit
import FluentKit

struct GoogleController: RouteCollection {
    private static let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("auth").grouped("google")
        
        e.post(use: verifyGoogleCredentials)
        e.get(use: methodNotAllowed)
        
        e.group("link") { f in
            f.post(use: linkGoogleAccount)
            f.get(use: methodNotAllowed)
        }
    }
    
    func verifyGoogleCredentials(req: Request) async throws -> AuthResponseBody {
        if #available(macOS 12, *) {
            let token: GoogleIdentityToken = try await req.jwt.google.verify()
            
            guard let email = token.email else {
                throw Abort(.badRequest, reason: "Missing email in identity token")
            }
            
            let user: UnregisteredUser = try await UnregisteredUser.query(on: req.db)
                    .filter(\.$email == email)
                    .first()
                    .unwrap(orError: Abort(.notFound, reason: "User not found"))
                    .get()
            let id = try user.requireID()
            let userCred: UserCredentials? = try await UserCredentials.query(on: req.db)
                .filter(\.$id == id)
                .first()
                .get()
            
            if let userCred = userCred {
                if !userCred.hasGoogle {
                    throw Abort(.forbidden, reason: "Please link your Google account")
                }
            } else {
                let userAuth: UserCredentials = try .init(id: user.requireID(), hasGoogle: true)
                let registeredUser: InitialRegisteredUser = try .init(user: user)
                
                do {
                    try await req.db.transaction { db in
                        try await registeredUser.create(on: db)
                        try await userAuth.create(on: db)
                    }
                } catch {
                    throw Abort(.internalServerError, reason: "Database error")
                }
            }
            
            return try await generateTokenPairResponse(req: req, id: user.requireID())
        }
        
        throw Abort(.internalServerError)
    }
    
    func linkGoogleAccount(req: Request) async throws -> GoogleLinkSuccess {
        if #available(macOS 12, *) {
            let token = try await req.jwt.google.verify()
            
            guard let email = token.email else {
                throw Abort(.badRequest, reason: "Missing email in identity token")
            }
            
            guard let idTokenString = req.body.string else {
                throw Abort(.badRequest, reason: "Please provide the access token")
            }
            
            let identityToken = try req.jwt.verify(idTokenString, as: IdentityToken.self)
            
            let userCred: UserCredentials = try await UserCredentials.query(on: req.db)
                .filter(\.$id == identityToken.id.value)
                .first()
                .unwrap(orError: Abort(.notFound, reason: "User not registered"))
                .get()
            
            if userCred.hasGoogle {
                throw Abort(.forbidden, reason: "Google account already linked")
            }
            
            let user: UnregisteredUser = try await UnregisteredUser.query(on: req.db)
                .filter(\.$id == identityToken.id.value)
                .first()
                .unwrap(orError: Abort(.notFound, reason: "User does not exist"))
                .get()
            
            if user.email.lowercased() != email.lowercased() {
                throw Abort(.badRequest, reason: "Email mismatch")
            }
            
            userCred.hasGoogle = true
            try await userCred.update(on: req.db)
            return .init(success: true)
        }
        throw Abort(.internalServerError)
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}

struct GoogleLinkSuccess: Content {
    let success: Bool
}
