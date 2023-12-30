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
    case unregisteredUsers = 0b100
}

extension Int {
    func hasPermission(_ permission: Permissions) -> Bool {
        let val = permission.rawValue
        return (self & val) == val || (self & 0b1 == 0b1)
    }
}

extension UserCredentials {
    func hasPermissions(_ permissions: [Permissions]) -> Bool {
        for permission in permissions {
            if !self.perm.hasPermission(permission) {
                return false
            }
        }
        return true
    }
    
    func hasPermission(_ permission: Permissions) -> Bool {
        return self.perm.hasPermission(permission)
    }
}

func createPermissionsInteger(_ perms: [Permissions]) -> Int {
    perms.reduce(0) { $0 | $1.rawValue }
}

func checkPermission(request: Request, _ perms: [Permissions]) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    guard let auth = try await UserCredentials.query(on: request.db)
        .filter(\.$id == token.id.value)
        .first() else {
        throw Abort(.unauthorized)
    }
    return auth.hasPermissions(perms)
}

func checkPermission(request: Request, _ perm: Permissions) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    guard let auth = try await UserCredentials.query(on: request.db)
        .filter(\.$id == token.id.value)
        .first() else {
        throw Abort(.unauthorized)
    }
    return auth.hasPermission(perm)
}
