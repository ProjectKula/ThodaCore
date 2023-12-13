//
//  SignupStatePayload.swift
//  
//
//  Created by Shrish Deshpande on 13/12/23.
//

import JWT

struct SignupStatePayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case id = "id"
        case state = "st"
    }
    
    var subject: SubjectClaim
    
    var expiration: ExpirationClaim
    
    var id: String
    
    var state: String
    
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
