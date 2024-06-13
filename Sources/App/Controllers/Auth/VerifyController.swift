//
//  VerifyController.swift
//
//
//  Created by Shrish Deshpande on 13/06/23.
//

import Vapor
import Fluent

struct VerifyController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.grouped("v0").grouped("auth").get("verify") { req in
            try await verifyAccessToken(req: req)
            return HTTPStatus.ok
        }
    }
}
