//
//  AvatarController.swift
//
//
//  Created by Shrish Deshpande on 14/12/23.
//

import Vapor
import Fluent
import Crypto

struct AvatarController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let e = routes.grouped("v0")
        
        e.post("avatar", use: uploadAvatar)
        e.delete("avatar", use: deleteAvatar)
    }

    func deleteAvatar(req: Request) async throws -> HTTPResponseStatus {
        let token = try await getAndVerifyAccessToken(req: req)
        let user = try await RegisteredUser.find(token.id, on: req.db)
        user?.avatarHash = nil
        do {
            try await user?.save(on: req.db)
        } catch {
            req.logger.error("Error saving user: \(error)")
        }
        return HTTPStatus.ok
    }
    
    func uploadAvatar(req: Request) async throws -> AvatarHashResponse {
        print("uploading avatar")
        
        let token = try await getAndVerifyAccessToken(req: req)
        let user = try await RegisteredUser.find(token.id, on: req.db)
        
        guard let user = user else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let data: ByteBuffer? = req.body.data
        
        guard let data = data else {
            throw Abort(.badRequest, reason: "No data found")
        }
        
        if data.readableBytes > 8_388_608 {
            throw Abort(.badRequest, reason: "File size too large")
        }

        let dataP = data.getData(at: 0, length: data.readableBytes)

        guard let dataP = dataP else {
            throw Abort(.badRequest, reason: "Could not read data")
        }
        
        let hash: String = Insecure.MD5.hash(data: dataP).map({ String(format: "%02hhx", $0) }).joined()
        print(hash);
        try await req.r2.post(dataP, id: hash)
        req.logger.info("Updated avatar for user \(user.id!) with hash \(hash)")
        user.avatarHash = hash
        try await user.update(on: req.db)
        return .init(hash: hash)
    }
}

struct AvatarRequest: Content, Codable {
    var avatar: Data
}

struct AvatarHashResponse: Content, Codable {
    var hash: String
}
