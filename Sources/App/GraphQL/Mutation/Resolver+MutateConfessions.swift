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

    func likeConfession(request: Request, arguments: IntIdArgs) async throws -> Int {
        try await assertScope(request: request, .confessions)
        let user = try await getContextUser(request)
        let confession = try await Confession.find(arguments.id, on: request.db).unwrap(or: Abort(.notFound)).get()
        try await confession.$likes.attach(user, on: request.db)
        return try await confession.$likes.query(on: request.db).count()
    }

    func unlikeConfession(request: Request, arguments: IntIdArgs) async throws -> Int {
        try await assertScope(request: request, .confessions)
        let user = try await getContextUser(request)
        let confession = try await Confession.find(arguments.id, on: request.db).unwrap(or: Abort(.notFound)).get()
        try await confession.$likes.detach(user, on: request.db)
        return try await confession.$likes.query(on: request.db).count()
    }
}
