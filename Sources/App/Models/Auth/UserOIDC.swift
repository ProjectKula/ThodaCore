//
//  UserOIDC.swift
//
//
//  Created by Shrish Deshpande on 07/03/24.
//

import Vapor
import Fluent

public final class UserOIDC: Model {
    public static var schema: String = "user_oidc"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Parent(key: "user_id")
    var user: RegisteredUser
    
    @Enum(key: "idp")
    public var idp: IdProvider
    
    @Field(key: "openid")
    public var openId: String
    
    @OptionalField(key: "url")
    public var url: String?
    
    @OptionalField(key: "email")
    public var email: String?
    
    public init() {}
    
    public init(id: UUID? = nil, user: RegisteredUser, idp: IdProvider, openId: String, url: String? = nil, email: String? = nil) {
        self.id = id
        self.$user.id = user.id!
        self.idp = idp
        self.openId = openId
        self.url = url
        self.email = email
    }
    
    public enum IdProvider: String, Codable {
        case apple, google, microsoft, discord, github, linkedIn
    }
    
    public func authUser(req: Request) async throws -> AuthResponseBody {
        return try await generateTokenPairResponse(req: req, id: self.$user.id)
    }
}
