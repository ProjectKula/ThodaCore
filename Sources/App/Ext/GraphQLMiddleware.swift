//
//  GraphQLMiddleware.swift
//
//
//  Created by Shrish Deshpande on 03/07/24.
//

import Vapor

struct GraphQLMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if (request.method == .POST && request.route?.path[0] == "graphql") {
            request.loaders = DataLoaders(on: request)
            request.token = try await getAccessToken(req: request)
        }
        return try await next.respond(to: request)
    }
}
