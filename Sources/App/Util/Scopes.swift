//
//  Permissions.swift
//
//
//  Created by Shrish Deshpande on 30/12/23.
//

import Foundation
import Vapor
import Fluent

enum Scopes: Int {
    case identity         = 0b1 // Read email, phone TODO: implement this
    case editProfile     = 0b10 // Query multiple users and/or unregistered users
    case createPosts    = 0b100 // Create Posts, like posts
    case deletePosts   = 0b1000 // Delete and restore posts
    case followUsers  = 0b10000 // Follow and unfollow users, manage followers
    case confessions = 0b100000 // Create confessions
    
    static let defaultScope: Int = create([
        .identity,
        .editProfile,
        .createPosts,
        .deletePosts,
        .followUsers
    ])
    
    static func create(_ perms: [Scopes]) -> Int {
        perms.reduce(0) { $0 | $1.rawValue }
    }
}

extension Int {
    func hasScope(_ scope: Scopes) -> Bool {
        let val = scope.rawValue
        return (self & val) == val || (self & 0b1 == 0b1)
    }
    
    func hasScope(_ scopes: [Scopes]) -> Bool {
        for perm in scopes {
            if !self.hasScope(perm) {
                return false
            }
        }
        return true
    }
}
