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
    case read             = 0b1 // Read all publicly availble data
    case identity        = 0b10 // Read email, phone TODO: implement this
    case editProfile    = 0b100 // Query multiple users and/or unregistered users
    case createPosts   = 0b1000 // Create Posts, like posts
    case deletePosts  = 0b10000 // Delete and restore posts
    case followUsers = 0b100000 // Follow and unfollow users, manage followers
    
    static let defaultScope: Int = create([
        .read,
        .identity,
        .editProfile,
        .createPosts,
        .deletePosts
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
