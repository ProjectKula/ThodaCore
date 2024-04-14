//
//  ResetController.swift
//
//
//  Created by Shrish Deshpande on 14/04/23.
//

import Vapor
import Fluent

struct ResetController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0").grouped("auth").grouped("password")

        e.patch("change", use: changePassword)
        e.post("reset", use: requestReset)
    }

    func changePassword(req: Request) async throws -> ChangePasswordResponse {
        let token = try await getAndVerifyAccessToken(req: req)
        guard let auth = try await UserPassword.query(on: req.db)
                .filter(\.$id == token.id)
                .first() else {
            return try await initPassword(token: token, req: req)
        }
        let body = try req.content.decode(ChangePasswordRequest.self)

        guard let currentPassword = body.currentPassword else {
            throw Abort(.badRequest, reason: "Current password is required")
        }

        guard try req.password.verify(currentPassword, created: auth.digest) else {
            throw Abort(.forbidden, reason: "Invalid password")
        }

        auth.digest = try req.password.hash(body.newPassword)
        try await auth.save(on: req.db)
        
        return .init(success: true)
    }

    func initPassword(token: IdentityToken, req: Request) async throws -> ChangePasswordResponse {
        let user = try await RegisteredUser.find(token.id, on: req.db)
          .unwrap(or: Abort(.notFound, reason: "User not found"))
          .get()
        let body = try req.content.decode(ChangePasswordRequest.self)
        let auth = try UserPassword(id: user.requireID(), digest: req.password.hash(body.newPassword))
        try await auth.save(on: req.db)
        return .init(success: true)
    }

    func requestReset(req: Request) async throws -> RegisteredUser {
        fatalError("Not implemented")
    }
}

struct ChangePasswordRequest: Content {
    var currentPassword: String?
    var newPassword: String
}

struct ChangePasswordResponse: Content {
    var success: Bool
}
