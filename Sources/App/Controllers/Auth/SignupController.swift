//
//  SignupController.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor
import Fluent
import Smtp
import JWT
import Redis

struct SignupController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0").grouped("auth").grouped("signup")
        
        e.post(use: initialSignup)
        e.get(use: methodNotAllowed)
        e.group("code") { e in
            e.get(use: methodNotAllowed)
            e.post(use: verifySignupCode)
        }
        e.group("cred") { e in
            e.post(use: setInitialCredentials)
            e.get(use: methodNotAllowed)
        }
    }
    
    func initialSignup(req: Request) async throws -> SignupStateResponseBody {
        let args: GetUserArgs
        
        do {
            args = try req.content.decode(GetUserArgs.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        let user = try await UnregisteredUser.query(on: req.db)
            .filter(\.$id == args.id)
            .filter(\.$email == args.email)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User does not exist"))
            .get()
        
        if await (try RegisteredUser.query(on: req.db).filter(\.$collegeId.$id == args.id).first() != nil) {
            throw Abort(.conflict, reason: "User already exists")
        }
        
        let payload: SignupStatePayload
        
        if req.headers.bearerAuthorization != nil {
            payload = try getAndVerifySignupState(req: req)
        } else {
            payload = SignupStatePayload(
                subject: "signupCode",
                expiration: .init(value: .init(timeIntervalSinceNow: 600)),
                id: try user.requireID(),
                email: user.email,
                state: [UInt8].random(count: 32).base64
            )
        }
        
        let code = try await getOrGenerateConfirmationCode(jwt: payload.state, req: req)

        let emailBody: View = try await req.view.render("signup", ["code": code])
        let body = emailBody.data.getString(at: 0, length: emailBody.data.readableBytes)
        
        let email = try Email(
            from: EmailAddress(address: appConfig.smtp.email, name: "Thoda Core"),
            to: [EmailAddress(address: user.email, name: user.name)],
            subject: "Your verification code",
            body: body ?? "Your verification code is \(code)",
            isBodyHtml: true
        )
        
        let sent = try await req.smtp.send(email) { message in
            req.application.logger.info("\(message)")
        }.get()
        let result: Bool
        
        do {
            result = try sent.get()
        } catch {
            throw Abort(.internalServerError, reason: "Failed to send email: \(error.localizedDescription)")
        }
        
        return SignupStateResponseBody(success: result, state: try req.jwt.sign(payload))
    }
    
    func verifySignupCode(req: Request) async throws -> SignupStateResponseBody {
        let args: SignupCodeRequest
        
        do {
            args = try req.content.decode(SignupCodeRequest.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        if req.headers.bearerAuthorization == nil {
            throw Abort(.unauthorized, reason: "Please provide the bearer token")
        }
        
        let payload = try getAndVerifySignupState(req: req)
        
        if payload.subject.value != "signupCode" {
            throw Abort(.badRequest, reason: "Invalid bearer token")
        }
        
        let storedCode = try await req.redis.get(.init(stringLiteral: payload.state), asJSON: Int.self)
        
        if storedCode == nil {
            throw Abort(.badRequest, reason: "No confirmation code present")
        } else if storedCode != Int(args.code) {
            throw Abort(.unauthorized, reason: "Invalid confirmation code")
        }
        
        let newPayload = SignupStatePayload(
            subject: "credentials",
            expiration: .init(value: .init(timeIntervalSinceNow: 600)),
            id: payload.id,
            email: payload.email,
            state: [UInt8].random(count: 32).base64
        )
        
        return SignupStateResponseBody(success: true, state: try req.jwt.sign(newPayload))
    }
    
    func setInitialCredentials(req: Request) async throws -> AuthResponseBody {
        let pwBody: InitialPasswordRequest
        
        do {
            pwBody = try req.content.decode(InitialPasswordRequest.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        let payload = try getAndVerifySignupState(req: req)
        
        if payload.subject.value != "credentials" {
            throw Abort(.badRequest, reason: "Invalid bearer token")
        }

        if (pwBody.password.count < 8) {
            throw Abort(.badRequest, reason: "Password must be at least 8 characters long")
        }
        
        let user = try await UnregisteredUser.query(on: req.db)
            .filter(\.$id == payload.id)
            .filter(\.$email == payload.email)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User does not exist"))
            .get()
        let registeredUser = try InitialRegisteredUser(user: user)
        try await registeredUser.create(on: req.db)
        let newUser = try await RegisteredUser.query(on: req.db)
            .filter(\.$collegeId.$id == payload.id)
            .first()
            .unwrap(or: Abort(.internalServerError, reason: "Could not create user"))
            .get()
        let userId = try newUser.requireID()
        let userPassword: UserPassword = try .init(req: req, id: userId, password: pwBody.password)
        try await userPassword.create(on: req.db)
        return try await generateTokenPairResponse(req: req, id: userId)
    }
    
    @inlinable
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}

struct InitialPasswordRequest: Content {
    let password: String
}

struct SignupStateResponseBody: Content {
    let success: Bool
    let state: String
}

struct SignupCodeRequest: Content {
    let code: String
}
