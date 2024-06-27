//
//  Notification.swift
//
//
//  Created by Shrish Deshpande on 24/06/24.
//

import Vapor
import Fluent
import Foundation

final class Notification: Model, Content {
    public static let schema = "notifications"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Parent(key: "target_user_id")
    var targetUser: RegisteredUser
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    @OptionalParent(key: "reference_post_id")
    var referencePost: Post?

    @OptionalParent(key: "reference_user_id")
    var referenceUser: RegisteredUser?

    public init() {
    }

    private static func create(type: NotificationType, targetUser: Int, referenceUser: Int? = nil, referencePost: String? = nil) -> Notification {
        let notif = Notification()
        notif.id = Snowflake.init().stringValue
        notif.$targetUser.id = targetUser
        notif.$referenceUser.id = referenceUser
        notif.$referencePost.id = referencePost
        notif.type = type
        return notif
    }

    public static func follow(targetUser: Int, referenceUser: Int) -> Notification {
        return create(type: .follow, targetUser: targetUser, referenceUser: referenceUser)
    }

    public static func like(target: Int, user: Int, post: String) -> Notification {
        return create(type: .like, targetUser: target, referenceUser: user, referencePost: post)
    }

    public static func comment(targetUser: Int, referenceUser: Int, referencePost: String) -> Notification {
        return create(type: .comment, targetUser: targetUser, referenceUser: referenceUser, referencePost: referencePost)
    }

    public static func mention(targetUser: Int, referenceUser: Int, referencePost: String) -> Notification {
        return create(type: .mention, targetUser: targetUser, referenceUser: referenceUser, referencePost: referencePost)
    }

    // TODO: add comment reference
    // TODO: add confession reference

    @Enum(key: "type")
    var type: NotificationType
    
    enum NotificationType: String, Codable {
        case follow
        case like
        case comment
        case mention
    }
}
