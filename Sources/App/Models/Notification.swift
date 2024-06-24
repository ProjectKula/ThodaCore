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
