//
//  AccessTokenPayload.swift
//
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT
import Vapor
import Redis
import Foundation
import Fluent

open class IdentityToken: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case id = "rgn"
        case expiration = "exp"
        case token = "tkn"
        case perm = "perm"
        case issuer = "iss"
    }
    
    public init(id: Int) {
        self.expiration = .init(value: .init(timeIntervalSinceNow: 86400))
        self.token = [UInt8].random(count: 64).base64
        self.perm = Scopes.defaultScope
        self.id = id
    }
    
    public convenience init(req: Request, collegeId userId: String) async throws {
        let user: RegisteredUser? = try await RegisteredUser.query(on: req.db)
            .filter(\.$collegeId.$id == userId)
            .first()
        guard let id = user?.id else {
            req.logger.error("Tried creating access token for non existant user '\(userId)'")
            throw Abort(.notFound)
        }
        
        self.init(id: id)
    }
    
    public var id: Int
    
    public var expiration: ExpirationClaim
    
    public var token: String
    
    public var perm: Int
    
    public var issuer: IssuerClaim = "thodaCore"
    
    open func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

public class UnverifiedIdentityToken: IdentityToken {
    override public func verify(using signer: JWTSigner) throws {
        // no-op
    }
}

struct RefreshTokenRequest: Content {
    var refreshToken: String
}

struct AuthResponseBody: Content {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int64
}

func refreshAccessTokenResponse(req: Request) async throws -> AuthResponseBody {
    let tokenPair = try await refreshAccessToken(req: req)
    let expiresAt = Int64(tokenPair.0.expiration.value.timeIntervalSince1970 * 1000) // Milliseconds
    return .init(accessToken: try req.jwt.sign(tokenPair.0), refreshToken: tokenPair.1, expiresAt: expiresAt)
}

func refreshAccessToken(req: Request) async throws -> (IdentityToken, String) {
    let oldToken = try req.jwt.verify(as: UnverifiedIdentityToken.self)
    try await blacklistToken(req: req, token: oldToken)
    let body = try req.content.decode(RefreshTokenRequest.self)
    guard let realToken = try await req.redis.get(.init(stringLiteral: body.refreshToken), as: String.self).get() else {
        req.logger.error("User '\(oldToken.id )' tried to refresh with a nonexistant token!")
        throw Abort(.badRequest, reason: "Invalid refresh token")
    }

    if realToken != oldToken.token {
        _ = try? await req.redis.delete([.init(stringLiteral: body.refreshToken)]).get()
        req.logger.error("User '\(oldToken.id)' tried to refresh an invalid token!")
        throw Abort(.badRequest, reason: "Invalid refresh token")
    }
    if try await req.redis.delete([.init(stringLiteral: body.refreshToken)]).get() < 1 {
        req.logger.error("Unable to delete refresh token '\(body.refreshToken)' from redis")
    }
    return try await generateStoredTokenPair(req: req, previous: oldToken)
}

@inlinable
func blacklistToken(req: Request, token: some IdentityToken) async throws {
    let interval = token.expiration.value.timeIntervalSinceNow
    if interval <= 0 {
        return
    }
    // Key : Value :: access token : "no"
    try await req.redis.setex(.init(stringLiteral: token.token), to: "no", expirationInSeconds: abs(Int(interval))).get()
}

func getAndVerifyAccessToken(req: Request) async throws -> IdentityToken {
    let payload = try req.jwt.verify(as: IdentityToken.self)
    
    if !(try await req.redis.get(.init(stringLiteral: payload.token)).get().isNull) {
        throw Abort(.unauthorized, reason: "Blacklisted access token")
    }
    
    return payload
}

func generateTokenPairResponse(req: Request, collegeId: String) async throws -> AuthResponseBody {
    let tokenPair = try await generateStoredTokenPair(req: req, collegeId: collegeId)
    let expiresAt = Int64(tokenPair.0.expiration.value.timeIntervalSince1970 * 1000)
    return .init(accessToken: try req.jwt.sign(tokenPair.0), refreshToken: tokenPair.1, expiresAt: expiresAt)
}

func generateStoredTokenPair(req: Request, collegeId: String) async throws -> (IdentityToken, String) {
    let tokenPair = try await generateTokenPair(req: req, collegeId: collegeId)
    try await req.redis.set(.init(stringLiteral: tokenPair.1), to: tokenPair.0.token).get()
    return tokenPair
}

@inlinable
func generateTokenPair(req: Request, collegeId: String) async throws -> (IdentityToken, String) {
    return (try await IdentityToken(req: req, collegeId: collegeId), [UInt8].random(count: 64).base64)
}

func generateStoredTokenPair(req: Request, previous: IdentityToken) async throws -> (IdentityToken, String) {
    let tokenPair = try await generateTokenPair(previous: previous)
    try await req.redis.set(.init(stringLiteral: tokenPair.1), to: tokenPair.0.token).get()
    return tokenPair
}

@inlinable
func generateTokenPair(previous: some IdentityToken) async throws -> (IdentityToken, String) {
    return (IdentityToken(id: previous.id), [UInt8].random(count: 64).base64)
}
