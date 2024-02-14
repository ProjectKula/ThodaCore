//
//  PermissionValidator.swift
//
//
//  Created by Shrish Deshpande on 02/01/24.
//

import Vapor
import Fluent


func checkScope(request: Request, _ scopes: [Scopes]) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    return token.perm.hasScope(scopes)
}

func checkScope(request: Request, _ scope: Scopes) async throws -> Bool {
    let token = try await getAndVerifyAccessToken(req: request)
    return token.perm.hasScope(scope)
}

func assertScope(request: Request, _ scopes: [Scopes]) async throws {
    if !(try await checkScope(request: request, scopes)) {
        throw Abort(.forbidden)
    }
}

func assertScope(request: Request, _ scope: Scopes) async throws {
    if !(try await checkScope(request: request, scope)) {
        throw Abort(.forbidden)
    }
}
