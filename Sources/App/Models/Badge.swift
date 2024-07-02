//
//  Badge.swift
//
//
//  Created by Shrish Deshpande on 02/07/24.
//

import Vapor
import Fluent

final class Badge: Model {
    public static let schema = "badges"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Parent(key: "user_id")
    var user: RegisteredUser

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "type")
    var type: BadgeType

    public init() { }

    init(_ type: BadgeType, user: RegisteredUser) throws {
        self.id = Snowflake.init().stringValue
        self.$user.id = try user.requireID()
        self.type = type
    }

    enum BadgeType: String, Codable {
        case admin
        case developer
    }
}
