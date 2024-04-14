//
//  LikedConfession.swift
//
//
//  Created by Shrish Deshpande on 14/04/24.
//

import Foundation

import Vapor
import Fluent

final class LikedConfession: Model, Content {
    public static let schema = "likedConfessions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "confessionId")
    var confession: Confession
    
    @Parent(key: "userId")
    var user: RegisteredUser
    
    init() {
    }
    
    init(confessionId: Int, userId: Int) {
        self.$confession.id = confessionId
        self.$user.id = userId
    }
}
