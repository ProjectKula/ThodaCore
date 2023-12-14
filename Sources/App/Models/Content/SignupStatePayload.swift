//
//  SignupStatePayload.swift
//  
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT
import Vapor

public struct SignupStatePayload: JWTPayload {
    public enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case id = "id"
        case email = "email"
        case state = "st"
    }
    
    public var subject: SubjectClaim
    
    public var expiration: ExpirationClaim
    
    public var id: String
    
    public var email: String
    
    public var state: String
    
    public func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

@inlinable
func getAndVerifySignupState(req: Request) throws -> SignupStatePayload {
    return try req.jwt.verify(as: SignupStatePayload.self)
}
