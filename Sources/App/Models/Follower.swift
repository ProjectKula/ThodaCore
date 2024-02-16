//
//  Follower.swift
//
//
//  Created by Shrish Deshpande on 16/02/24.
//

import Foundation
import Vapor
import Fluent

final class Follower: Model, Content {
    public static let schema = "followers"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "follower_id")
    var follower: RegisteredUser
    
    @Parent(key: "followed_id")
    var followed: RegisteredUser
    
    init() {
    }
    
    init(follower: Int, followed: Int) {
        self.$follower.id = follower
        self.$followed.id = followed
    }
}
