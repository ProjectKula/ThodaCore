//
//  Confession.swift
//
//
//  Created by Shrish Deshpande on 19/02/24.
//

import Vapor
import Fluent
import Foundation
import FluentPostgresDriver

final class Confession: Model, Content, PostgresDecodable {
    static var schema: String = "confessions"
    
    @ID(custom: "id", generatedBy: .user)
    var id: Int?
    
    @Parent(key: "creator")
    var creator: RegisteredUser
    
    @Field(key: "content")
    var content: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    @Siblings(through: LikedConfession.self, from: \.$confession, to: \.$user)
    var likes: [RegisteredUser]
    
    init() {
    }
    
    init(creatorId: Int, content: String) {
        self.$creator.id = creatorId
        self.content = content
    }
}
