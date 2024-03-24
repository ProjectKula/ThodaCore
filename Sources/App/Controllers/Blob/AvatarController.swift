//
//  AvatarController.swift
//
//
//  Created by Shrish Deshpande on 14/12/23.
//

import Vapor
import Fluent

struct AvatarController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0")
        
        e.post("avatar", use: uploadAvatar)
    }
    
    func uploadAvatar(req: Request) async throws -> Bool {
        let token = try await getAndVerifyAccessToken(req: req)

        let user = try await RegisteredUser.find(token.id, on: req.db)
        let data: ByteBuffer? = req.body.data
        
        return try await UserPassword.query(on: req.db)
            .join(RegisteredUser.self, on: \UserPassword.$id == \RegisteredUser.$id)
            .filter(RegisteredUser.self, \.$email == args.email)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User does not exist"))
            .get()
            .auth(req: req, args: args)
    }
}
