//
//  PermissionValidator.swift
//
//
//  Created by Shrish Deshpande on 02/01/24.
//

import Vapor
import Fluent


func checkPermission(request: Request, _ perms: [Permissions]) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    return token.perm.hasPermissions(perms)
}

func checkPermission(request: Request, _ perm: Permissions) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    return token.perm.hasPermission(perm)
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
