//
//  Permissions.swift
//
//
//  Created by Shrish Deshpande on 30/12/23.
//

import Foundation
import Vapor
import Fluent

enum Permissions: Int {
    case admin             = 0b1 // All permissions
    case read             = 0b10 // Read all publicly availble data
    case identity        = 0b100 // Read email, phone TODO: implement this
    case query          = 0b1000 // Query multiple users and/or unregistered users
    case editProfile   = 0b10000 // Edit profile
    case createPosts  = 0b100000 // Create Posts, like posts
    case deletePosts = 0b1000000 // Delete and restore posts
    
    static let defaultPermission: Int = create([.read, .editProfile, .createPosts, .deletePosts])
    
    static func create(_ perms: [Permissions]) -> Int {
        perms.reduce(0) { $0 | $1.rawValue }
    }
}

extension Int {
    func hasPermission(_ permission: Permissions) -> Bool {
        let val = permission.rawValue
        return (self & val) == val || (self & 0b1 == 0b1)
    }
    
    func hasPermissions(_ permissions: [Permissions]) -> Bool {
        for perm in permissions {
            if !self.hasPermission(perm) {
                return false
            }
        }
        return true
    }
}
