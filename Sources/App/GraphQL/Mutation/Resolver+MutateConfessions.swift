//
//  Resolver+MutateConfessions.swift
//
//
//  Created by Shrish Deshpande on 19/02/24.
//

import Vapor
import Graphiti
import Fluent

extension Resolver {
    func confess(request: Request, arguments: CreatePostArgs) async throws -> Confession {
        let token = try await getAndVerifyAccessToken(req: request)
        try await assertScope(request: request, .confessions)
        let confession: Confession = .init(creatorId: token.id, content: arguments.content)
        try await confession.create(on: request.db)
        return confession
    }
}
