//
//  PermissionValidator.swift
//
//
//  Created by Shrish Deshpande on 02/01/24.
//

import Vapor
import Fluent

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


func checkPermission(request: Request, _ perms: [Permissions]) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    let auth = try await UserCredentials.query(on: request.db)
        .filter(\.$id == token.id.value)
        .first()
        .unwrap(orError: Abort(.unauthorized))
        .get()
    return auth.hasPermissions(perms)
}

func checkPermission(request: Request, _ perm: Permissions) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    let auth = try await UserCredentials.query(on: request.db)
        .filter(\.$id == token.id.value)
        .first()
        .unwrap(orError: Abort(.unauthorized))
        .get()
    return auth.hasPermission(perm)
}

func assertPermission(request: Request, _ perm: [Permissions]) async throws {
    if !(try await checkPermission(request: request, perm)) {
        throw Abort(.forbidden)
    }
}

func assertPermission(request: Request, _ perm: Permissions) async throws {
    if !(try await checkPermission(request: request, perm)) {
        throw Abort(.forbidden)
    }
}
