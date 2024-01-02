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
    case admin = 0b1
    case identity = 0b10
    case query = 0b100
    
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
