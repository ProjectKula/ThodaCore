//
//  AccessTokenPayload.swift
//
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT
import Vapor

class AccessTokenPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case id = "sub"
        case expiration = "exp"
        case token = "tkn"
        case issuer = "iss"
    }
    
    init(id: String) {
        self.expiration = .init(value: .init(timeIntervalSinceNow: 86400))
        self.id = .init(stringLiteral: id)
        self.token = [UInt8].random(count: 8).base64
    }
    
    var id: SubjectClaim
    
    var expiration: ExpirationClaim
    
    var token: String
    
    var issuer: String = "thodaCore"
    
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
