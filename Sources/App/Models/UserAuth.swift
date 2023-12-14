//
//  UserAuth.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor
import Fluent
import Crypto

final class UserAuth: Model, Content {
    static let schema = "userAuth"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Field(key: "salt")
    var salt: [UInt8]
    
    @Field(key: "hash")
    var hash: [UInt8]
    
    init() { }
    
    init(id: String, pw: String) throws {
        self.id = id
        self.salt = [UInt8].random(count: 16)
        self.hash = try combineSaltAndHash(pw: pw, salt: self.salt)
    }
    
    init(id: String, salt: [UInt8], hash: [UInt8]) {
        self.id = id
        self.salt = salt
        self.hash = hash
    }
}

func combineSaltAndHash(pw: String, salt: [UInt8]) throws -> [UInt8] {
    guard let passwordData = pw.data(using: .utf8) else {
        throw Abort(.internalServerError, reason: "Error resolving password")
    }
    
    var combinedData = Data()
    combinedData.append(passwordData)
    combinedData.append(contentsOf: salt)
    
    let hashedData = SHA256.hash(data: combinedData).map { el in
        return el as UInt8
    }
    
    return hashedData
}
