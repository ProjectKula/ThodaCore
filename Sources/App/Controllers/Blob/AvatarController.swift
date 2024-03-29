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
    }
    
    func uploadAvatar(req: Request) async throws -> AvatarHashResponse {
        print("uploading avatar")
        //let body = try req.content.decode(AvatarRequest.self)
        //print(body.avatar.base64EncodedString())

        //if true { throw Abort(.badRequest, reason: "Actually a good request") }
        
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
        print("ok cool \(hash)")
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
