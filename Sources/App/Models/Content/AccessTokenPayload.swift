//
//  AccessTokenPayload.swift
//
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT
import Vapor
import Redis

open class AccessTokenPayload: JWTPayload {
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
    
    public var issuer: String = "thodaCore"
    
    open func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

public class UnverifiedAccessTokenPayload: AccessTokenPayload {
    override public func verify(using signer: JWTSigner) throws {
        // no-op
    }
}

struct RefreshTokenRequest: Content {
    var refreshToken: String
}

func refreshAccessToken(req: Request) async throws -> (AccessTokenPayload, String) {
    let oldToken = try req.jwt.verify(as: UnverifiedAccessTokenPayload.self)
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
    return try await generateTokenPair(req: req, id: oldToken.id.value)
}

@inlinable
func blacklistToken(req: Request, token: some AccessTokenPayload) async throws {
    let interval = token.expiration.value.timeIntervalSinceNow
    if interval.sign == .minus {
        return
    }
    try await req.redis.setex(.init(stringLiteral: token.token), toJSON: "no", expirationInSeconds: abs(Int(interval)))
}

func getAndVerifyAccessToken(req: Request) async throws -> AccessTokenPayload {
    let payload = try req.jwt.verify(as: AccessTokenPayload.self)
    
    if try await req.redis.get(.init(stringLiteral: payload.token)).get().isNull {
        throw Abort(.unauthorized, reason: "Blacklisted access token")
    }
    
    return payload
}

func generateTokenPair(req: Request, id: String) async throws -> (AccessTokenPayload, String) {
    let tokenPair = generateTokenPair(id: id)
    try await req.redis.set(.init(stringLiteral: tokenPair.1), to: id).get()
    return tokenPair
}

@inlinable
func generateTokenPair(id: String) -> (AccessTokenPayload, String) {
    return (AccessTokenPayload(id: id), [UInt8].random(count: 64).base64)
}
