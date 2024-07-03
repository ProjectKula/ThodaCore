//
//  Badge+Resolver.swift
//
//
//  Created by Shrish Deshpande on 02/07/24.
//

import Vapor
import Fluent
import Graphiti

extension Badge {
    func getUser(request: Request, arguments: NoArguments) async throws -> RegisteredUser {
        return try await request.loaders.users.load(key: self.$user.id, on: request.eventLoop)
    }
}
