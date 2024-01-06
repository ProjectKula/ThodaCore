//
//  LikedPost.swift
//
//
//  Created by Shrish Deshpande on 06/01/24.
//

import Foundation

import Vapor
import Fluent

final class LikedPost: Model, Content {
    public static let schema = "likedPosts"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "postId")
    var post: Post
    
    @Parent(key: "userId")
    var user: RegisteredUser
    
    init() {
    }
    
    init(postId: String, userId: Int) {
        self.$post.id = postId
        self.$user.id = userId
    }
}
