//
//  UserPassword.swift
//
//
//  Created by Shrish Deshpande on 07/03/24.
//

import Foundation

import Vapor
import Fluent
import Crypto

public final class UserPassword: Model {
    public static let schema = "passwords"
    
    @ID(custom: "id", generatedBy: .user)
    public var id: Int?
    
    @Field(key: "digest")
    public var digest: String
    
    public init() {
    }
    
    public init(id: Int, digest: String) {
        self.id = id
        self.digest = digest
    }
    
    public convenience init(req: Request, id: Int, password: String) throws {
        self.init(id: id, digest: try req.password.hash(password))
    }
    
    public func auth(req: Request, args: any PasswordProvider) async throws -> AuthResponseBody {
        if try req.password.verify(args.password, created: digest) {
            return try await generateTokenPairResponse(req: req, id: try self.requireID())
        }
        
        throw Abort(.forbidden, reason: "Invalid password")
    }
}

public protocol PasswordProvider {
    var password: String { get }
}
