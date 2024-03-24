//
//  AvatarController.swift
//
//
//  Created by Shrish Deshpande on 14/12/23.
//

import Vapor
import Fluent
import SwiftCrypto

struct AvatarController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0")
        
        e.post("avatar", use: uploadAvatar)
    }
    
    func uploadAvatar(req: Request) async throws -> Bool {
        let token = try await getAndVerifyAccessToken(req: req)
        let data: ByteBuffer? = req.body.data
        guard let data = data else {
            throw Abort(.badRequest, reason: "No data found")
        }
        if data.readableBytes > 1_000_000 {
            throw Abort(.badRequest, reason: "File size too large")
        }
        let hash: String = Insecure.MD5.hash(data: data).map({ String(format: "%02hhx", $0) }).joined()
        
        let user = try await RegisteredUser.find(token.id, on: req.db)

    }
}
