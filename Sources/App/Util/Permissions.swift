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
    case admin = 0b1     // All permissions
    case identity = 0b10 // See identity of self and others
    case query = 0b100   // Query multiple users and/or unregistered users
    
    static func create(_ perms: [Permissions]) -> Int {
        perms.reduce(0) { $0 | $1.rawValue }
    }
}

extension Int {
    func hasPermission(_ permission: Permissions) -> Bool {
        let val = permission.rawValue
        return (self & val) == val || (self & 0b1 == 0b1)
    }
}
