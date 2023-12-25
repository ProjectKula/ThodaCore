//
//  UserAuth.swift
//
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Vapor
import Fluent
import Crypto

final class UserCredentials: Model, Content {
    static let schema = "userCred"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Field(key: "salt")
    var salt: Data
    
    @Field(key: "hash")
    var hash: Data
    
    init() { }
    
    init(id: String, pw: String) throws {
        self.id = id
        var saltData = Data()
        saltData.append(contentsOf: [UInt8].random(count: 16))
        self.salt = saltData
        self.hash = try combineSaltAndHash(pw: pw, salt: self.salt)
    }
    
    init(id: String, salt: Data, hash: Data) {
        self.id = id
        self.salt = salt
        self.hash = hash
    }
}

func authUserWithPassword(req: Request, args: LoginAuthRequest) async throws -> Bool {
    let auth = try await UserCredentials.query(on: req.db)
        .filter(\.$id == args.id)
        .first()
        .unwrap(orError: Abort(.notFound, reason: "Could not find user with id \(args.id)"))
        .get()
    let hash = try combineSaltAndHash(pw: args.pw, salt: auth.salt)
    return hash == auth.hash
}

func combineSaltAndHash(pw: String, salt: Data) throws -> Data {
    guard var passwordData = pw.data(using: .utf8) else {
        throw Abort(.internalServerError, reason: "Error resolving password")
    }
    
    passwordData.append(salt)
    
    let hashedData = SHA256.hash(data: passwordData).map { el in
        return el as UInt8
    }
    
    var hashedDataData = Data()
    hashedDataData.append(contentsOf: hashedData)
    
    return hashedDataData
}

struct LoginAuthRequest: Content {
    let id: String
    let pw: String
}
