//
//  AccessTokenPayload.swift
//
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT
import Vapor

public class AccessTokenPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case id = "sub"
        case expiration = "exp"
        case token = "tkn"
        case issuer = "iss"
    }
    
    public init(id: String) {
        self.expiration = .init(value: .init(timeIntervalSinceNow: 86400))
        self.id = .init(stringLiteral: id)
        self.token = [UInt8].random(count: 8).base64
    }
    
    public var id: SubjectClaim
    
    public var expiration: ExpirationClaim
    
    public var token: String
    
    public var issuer: String = "thodaCore"
    
    public func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

@inlinable
func generateTokenPair(id: String) -> (AccessTokenPayload, String) {
    return (AccessTokenPayload(id: id), [UInt8].random(count: 8).base64)
}
