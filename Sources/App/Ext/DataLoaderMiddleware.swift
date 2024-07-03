
//
//  DataLoaderMiddleware.swift
//
//
//  Created by Shrish Deshpande on 03/07/24.
//

import Vapor

struct DataLoaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if (request.method == .POST) {
            request.loaders = DataLoaders()
        }
        return try await next.respond(to: request)
    }
}
