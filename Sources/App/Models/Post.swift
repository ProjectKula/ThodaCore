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
    
    @Field(key: "user")
    var user: Int
    
    @Field(key: "content")
    var content: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "deleted")
    var deleted: Bool
    
    init() {
    }
    
    // TODO: attachments (media), comments enabled, edited
    init(id: String, regNo user: Int, content: String) {
        self.id = id
        self.user = user
        self.content = content
        self.deleted = false
    }
}
