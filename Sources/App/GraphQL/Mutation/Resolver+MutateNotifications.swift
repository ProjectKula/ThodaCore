//
//  Resolver+MutateNotifications.swift
//
//
//  Created by Shrish Deshpande on 27/06/24.
//

import Vapor
import Fluent
import Graphiti
 
extension Resolver {
    func readAllNotifications(request: Request, arguments: NoArguments) async throws -> Int {
        try await assertScope(request: request, .editProfile)
        let user = try await getContextUser(request)
        let notifications = try await user.$notifications.query(on: request.db).all()
        let count = try await request.db.transaction { db in
            var ct = 0
            for notif in notifications {
                try await notif.delete(on: db)
                ct += 1
            }
            return ct
        }
        return count
    }

    func readNotification(request: Request, arguments: StringIdArgs) async throws -> Bool {
        try await assertScope(request: request, .editProfile)
        let user = try await getContextUser(request)
        let notification = try await user.$notifications.query(on: request.db).filter(\.$id == arguments.id).first()
        guard let notif = notification else {
            throw Abort(.notFound, reason: "Notification not found")
        }
        try await notif.delete(on: request.db)
        return true
    }
}
