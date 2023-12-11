//
//  UserAuth.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor
import Fluent

final class UserAuth: Model, Content {
    static let schema = "userAuth"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Field(key: "salt")
    var salt: String
    
    @Field(key: "hash")
    var hash: String
    
    init() { }
    
    init(id: String, salt: String, hash: String) {
        self.id = id
        self.salt = salt
        self.hash = hash
    }
}
