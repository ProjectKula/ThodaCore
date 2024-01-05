//
//  Post.swift
//
//
//  Created by Shrish Deshpande on 05/01/24.
//

import Vapor
import Fluent

final class Post: Model, Content {
    public static let schema = "posts"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Parent(key: "userId")
    var user: RegisteredUser
    
    @Field(key: "content")
    var content: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "deleted")
    var deleted: Bool
    
    init() {
    }
    
    // TODO: attachments (media), comments enabled, edited
    init(id: String, userId: Int, content: String) {
        self.id = id
        self.$user.id = userId
        self.content = content
        self.deleted = false
    }
}
