//
//  AuthController.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor
import Fluent
import Smtp
import JWT
import Redis

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.group("login") { e in
            e.post(use: initialAuth)
            e.get(use: methodNotAllowed)
        }
        
        auth.group("signup") { e in
            e.post(use: initialSignup)
            e.get(use: methodNotAllowed)
            e.group("code") { e in
                e.get(use: methodNotAllowed)
                e.post(use: verifySignupCode)
            }
        }
        
        auth.group("refresh") { e in
            e.post(use: methodNotAllowed)
            e.get(use: methodNotAllowed)
        }
    }
    
    func initialAuth(req: Request) async throws -> AuthResponseBody {
        let params: LoginAuthRequest
        
        do {
            params = try req.content.decode(LoginAuthRequest.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        throw Abort(.notImplemented, reason: "we have no users yet \(params.id)")
    }
    
    func initialSignup(req: Request) async throws -> SignupCodeResponseBody {
        let args: GetUserArgs
        
        do {
            args = try req.content.decode(GetUserArgs.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        let user = try await Resolver.instance.getUser(request: req, arguments: args).get()
        
        if await (try RegisteredUser.query(on: req.db).filter(\.$id == args.id).first() != nil) {
            throw Abort(.conflict, reason: "User already exists")
        }
        
        let payload: SignupStatePayload
        
        if req.headers.bearerAuthorization != nil {
            payload = try req.jwt.verify(as: SignupStatePayload.self)
        } else {
            payload = SignupStatePayload(
                subject: "signup",
                expiration: .init(value: .init(timeIntervalSinceNow: 600)),
                id: try user.requireID(),
                email: user.email,
                state: [UInt8].random(count: 32).base64
            )
        }
        
        let code = try await getOrGenerateConfirmationCode(jwt: payload.state, req: req)
        
        let email = try Email(
            from: EmailAddress(address: AppConfig.defaultEmail, name: "Thoda Core"),
            to: [EmailAddress(address: user.email, name: user.name)],
            subject: "Your verification code",
            body: "Your verification code is: \(code)"
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
        
        return SignupCodeResponseBody(success: result, state: try req.jwt.sign(payload))
    }
    
    func verifySignupCode(req: Request) async throws -> AuthResponseBody {
        let args: SignupCodeRequest
        
        do {
            args = try req.content.decode(SignupCodeRequest.self)
        } catch {
            throw Abort(.badRequest, reason: "Invalid request: \(error.localizedDescription)")
        }
        
        if req.headers.bearerAuthorization == nil {
            throw Abort(.unauthorized, reason: "Please provide the bearer token")
        }
        
        let payload = try req.jwt.verify(as: SignupStatePayload.self)
        let storedCode = try await req.redis.get(RedisKey(stringLiteral: payload.state), asJSON: Int.self)
        
        if storedCode == nil {
            throw Abort(.badRequest, reason: "No confirmation code present")
        } else if storedCode != Int(args.code) {
            throw Abort(.unauthorized, reason: "Invalid confirmation code")
        }
        
        let user = try await Resolver.instance.getUser(request: req, arguments: .init(id: payload.id, email: payload.email)).get()
        let registeredUser = try RegisteredUser(user: user)
        try await registeredUser.save(on: req.db)
        
        throw Abort(.notImplemented, reason: "Signup is complete but password is not")
    }
    
    func refreshToken(req: Request) async throws -> AuthResponseBody {
        throw Abort(.notImplemented)
    }
    
    func methodNotAllowed(req: Request) async throws -> AuthResponseBody {
        throw Abort(.methodNotAllowed)
    }
}

struct LoginAuthRequest: Content {
    let id: String
    let pw: String
}

struct AuthResponseBody: Content {
    let accessToken: String
    let refreshToken: String
}

struct SignupCodeResponseBody: Content {
    let success: Bool
    let state: String
}

struct SignupCodeRequest: Content {
    let code: String
}
