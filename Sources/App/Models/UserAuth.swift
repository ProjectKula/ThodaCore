//
//  UserAuth.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor
import Fluent
import CryptoKit

final class UserAuth: Model, Content {
    static let schema = "userAuth"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Field(key: "salt")
    var salt: [UInt8]
    
    @Field(key: "hash")
    var hash: [UInt8]
    
    init() { }
    
    init(id: String, salt: [UInt8], hash: [UInt8]) {
        self.id = id
        self.salt = salt
        self.hash = hash
    }
}
