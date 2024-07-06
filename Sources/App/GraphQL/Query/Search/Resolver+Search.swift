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
            
            let userResult = try await pgdb.query("SELECT * FROM \"registeredUsers\" WHERE tsv @@ to_tsquery($1)", [.init(string: search)]).get()
            let users = try userResult.rows.map { try $0.decode(MetaRegisteredUser.self) }.map { $0.convert() }
            

            //let postResult = try await pgdb.query("SELECT * FROM posts WHERE tsv @@ to_tsquery($1)", [.init(string: search)]).get()
            //let posts = try postResult.rows.map { try $0.decode(Post.self) }

            //let confessionResult = try await pgdb.query("SELECT * FROM confessions WHERE tsv @@ to_tsquery($1)", [.init(string: search)]).get()
            //let confessions = try confessionResult.rows.map { try $0.decode(Confession.self) }

            let searchResults: [any SearchResult] = users.map { $0 }// + posts.map { $0 } + confessions.map { $0 }
            return searchResults.sorted { $0.createdAt! > $1.createdAt! }
        } catch {
            request.logger.error("\(String(reflecting: error))")
            request.logger.error("Error while searching: \(error)")
            throw Abort(.internalServerError)
        }
    }
}
