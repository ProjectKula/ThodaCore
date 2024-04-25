//
//  ResetController.swift
//
//
//  Created by Shrish Deshpande on 14/04/23.
//

import Vapor
import Fluent
import Redis
import Smtp

struct ResetController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0").grouped("auth").grouped("password")

        e.patch("change", use: changePassword)
        e.group("reset") { e in
            e.post("request", use: requestReset)
            e.post("verify", use: verifyReset)
            e.post("password", use: passwordReset)
        }
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

    func requestReset(req: Request) async throws -> ChangePasswordResponse {
        let body = try req.content.decode(RequestResetRequest.self)
        guard let user = try await RegisteredUser.query(on: req.db)
          .filter(\.$email == body.email)
          .first() else {
            req.application.logger.warning("User with email \(body.email) not found")
            throw Abort(.noContent);
        }
        let urlPrefix = "http://localhost:5173/reset"
        let nonce = [UInt8].random(count: 64).base64.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        let _ = req.redis.setex(.init(nonce), to: user.id, expirationInSeconds: 43200).map {
            req.logger.info("Set password request nonce \(nonce)");
        }
        let url = "\(urlPrefix)?nonce=\(nonce)"
        let emailBody: View = try await req.view.render("reset", ["url": url])
        let emailBodyStr = emailBody.data.getString(at: 0, length: emailBody.data.readableBytes)
        
        let email = try Email(
          from: EmailAddress(address: appConfig.smtp.email, name: "Thoda Core"),
          to: [EmailAddress(address: user.email, name: user.name)],
          subject: "Reset your password",
          body: emailBodyStr ?? "A password reset has been requested for your account. If you did not request this, please ignore this email. To reset your password, click the following link: \(url)");
        let _: EventLoopFuture<Result<Bool, Error>> = req.smtp.send(email) { message in
            req.application.logger.info("\(message)")
        }
        
        throw Abort(.noContent);
    }

    func verifyReset(req: Request) async throws -> NonceResponse {
        let nonce = try req.query.get(String.self, at: "nonce")
        req.logger.info("Received password request nonce \(nonce)")
        let id: Int = try await req.redis.get(.init(nonce), as: Int.self).unwrap(or: Abort(.notFound, reason: "Invalid or expired nonce")).get()
        let _ = try await req.redis.delete(.init(nonce)).get()
        let newNonce = [UInt8].random(count: 64).base64.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        let _ = req.redis.setex(.init(newNonce), to: id, expirationInSeconds: 600).map {
            req.logger.info("Set password reset nonce \(newNonce)")
        }
        return .init(nonce: newNonce)
    }

    func passwordReset(req: Request) async throws -> ChangePasswordResponse {
        let body = try req.content.decode(ChangePasswordRequest.self)
        let nonce = try req.query.get(String.self, at: "nonce")
        req.logger.info("Received password reset nonce \(nonce)");
        let id: Int = try await req.redis.get(.init(nonce), as: Int.self).unwrap(or: Abort(.notFound, reason: "Invalid or expired nonce")).get()
        let _ = try await req.redis.delete(.init(nonce)).get()
        if let password = try await UserPassword.query(on: req.db)
             .filter(\.$id == id)
             .first() {
            try await password.delete(on: req.db)
        }
        let newPassword: UserPassword = .init(id: id, digest: try req.password.hash(body.newPassword))
        try await newPassword.save(on: req.db)
        return .init(success: true)
    }
}

struct ChangePasswordRequest: Content {
    var currentPassword: String?
    var newPassword: String
}

struct ChangePasswordResponse: Content {
    var success: Bool
}

struct RequestResetRequest: Content {
    var email: String
}

struct NonceResponse: Content {
    var nonce: String
}
