//
//  Resolver+Search.swift
//
//
//  Created by Shrish Deshpande on 06/07/24.
//

import Vapor
import Fluent
import FluentPostgresDriver

struct SearchQueryArgs: Codable {
    let query: String
}

fileprivate struct MetaRegisteredUser: Codable, PostgresDecodable {
    let id: Int
    let collegeid: String
    let name: String
    let phone: String
    let email: String
    let personal_email: String
    let branch: String
    let gender: String
    let pronouns: String?
    let date_registered: Date?
    let bio: String?
    let intake_year: Int
    let avatar_hash: String?

    func convert() -> RegisteredUser {
        let user: RegisteredUser = .init(collegeId: self.collegeid, name: self.name, phone: self.phone, email: self.email, personalEmail: self.personal_email, branch: self.branch, gender: self.gender, pronouns: self.pronouns, bio: self.bio, intakeYear: self.intake_year , id: self.id)
        user.dateRegistered = self.date_registered
        user.avatarHash = self.avatar_hash
        return user
    }
}

extension Resolver {
    func search(request: Request, arguments: SearchQueryArgs) async throws -> [any SearchResult] {
        do {
            let pgdb = request.db as! PostgresDatabase
            let search = arguments.query
            
            let userResult = try await pgdb.query("SELECT id FROM \"registeredUsers\" WHERE tsv @@ to_tsquery($1)", [.init(string: search)]).get()
            let userIds = try userResult.rows.map { try $0.decode(Int.self) }
            let users = try await request.loaders.users.loadMany(keys: userIds, on: request.eventLoop)
            let postResult = try await pgdb.query("SELECT id FROM posts WHERE tsv @@ to_tsquery($1)", [.init(string: search)]).get()
            let postIds = try postResult.rows.map { try $0.decode(String.self) }
            let posts = try await request.loaders.posts.loadMany(keys: postIds, on: request.eventLoop)

            let confessionResult = try await pgdb.query("SELECT * FROM confessions WHERE tsv @@ to_tsquery($1)", [.init(string: search)]).get()
            let confessionIds = try confessionResult.rows.map { try $0.decode(Int.self) }
            let confessions = try await request.loaders.confessions.loadMany(keys: confessionIds, on: request.eventLoop)

            let searchResults: [any SearchResult] = users.map { $0 } + posts.map { $0 } + confessions.map { $0 }
            return searchResults.sorted { $0.created
                                          At! > $1.createdAt! }
        } catch {
            request.logger.error("\(String(reflecting: error))")
            request.logger.error("Error while searching: \(error)")
            throw Abort(.internalServerError)
        }
    }
}
