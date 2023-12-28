//
//  AccessTokenPayload.swift
//
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT
import Vapor
import Redis

open class IdentityToken: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case id = "sub"
        case expiration = "exp"
        case token = "tkn"
        case issuer = "iss"
    }
    
    public init(id: String) {
        self.expiration = .init(value: .init(timeIntervalSinceNow: 86400))
        self.id = .init(stringLiteral: id)
        self.token = [UInt8].random(count: 64).base64
    }
    
    public var id: SubjectClaim
    
    public var expiration: ExpirationClaim
    
    public var token: String
    
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
}

func refreshAccessTokenResponse(req: Request) async throws -> AuthResponseBody {
    let tokenPair = try await refreshAccessToken(req: req)
    return .init(accessToken: try req.jwt.sign(tokenPair.0), refreshToken: tokenPair.1)
}

func refreshAccessToken(req: Request) async throws -> (IdentityToken, String) {
    let oldToken = try req.jwt.verify(as: UnverifiedIdentityToken.self)
    try await blacklistToken(req: req, token: oldToken)
    let body = try req.content.decode(RefreshTokenRequest.self)
    guard let realToken = try await req.redis.get(.init(stringLiteral: body.refreshToken), asJSON: String.self) else {
        throw Abort(.badRequest, reason: "Invalid refresh token")
    }
    if realToken != oldToken.token {
        _ = try? await req.redis.delete([.init(stringLiteral: body.refreshToken)]).get()
        req.logger.error("User \(oldToken.id) tried to refresh an invalid token!")
        throw Abort(.badRequest, reason: "Invalid refresh token")
    }
    if try await req.redis.delete([.init(stringLiteral: body.refreshToken)]).get() < 1 {
        req.logger.error("Unable to delete refresh token \(body.refreshToken) from redis")
    }
    return try await generateStoredTokenPair(req: req, id: oldToken.id.value)
}

@inlinable
func blacklistToken(req: Request, token: some IdentityToken) async throws {
    let interval = token.expiration.value.timeIntervalSinceNow
    if interval.sign == .minus {
        return
    }
    // Key : Value :: access token : "no"
    try await req.redis.setex(.init(stringLiteral: token.token), toJSON: "no", expirationInSeconds: abs(Int(interval)))
}

func getAndVerifyAccessToken(req: Request) async throws -> IdentityToken {
    let payload = try req.jwt.verify(as: IdentityToken.self)
    
    if try await req.redis.get(.init(stringLiteral: payload.token)).get().isNull {
        throw Abort(.unauthorized, reason: "Blacklisted access token")
    }
    
    return payload
}

func generateTokenPairResponse(req: Request, id: String) async throws -> AuthResponseBody {
    let tokenPair = try await generateStoredTokenPair(req: req, id: id)
    return .init(accessToken: try req.jwt.sign(tokenPair.0), refreshToken: tokenPair.1)
}

func generateStoredTokenPair(req: Request, id: String) async throws -> (IdentityToken, String) {
    let tokenPair = generateTokenPair(id: id)
    try await req.redis.set(.init(stringLiteral: tokenPair.1), to: id).get()
    return tokenPair
}

@inlinable
func generateTokenPair(id: String) -> (IdentityToken, String) {
    return (IdentityToken(id: id), [UInt8].random(count: 64).base64)
}
