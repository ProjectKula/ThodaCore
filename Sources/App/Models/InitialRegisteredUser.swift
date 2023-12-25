//
//  InitialRegisteredUser.swift
//  
//
//  Created by Shrish Deshpande on 25/12/23.
//

import Vapor
import Fluent


/// Represents a user that has just registered.
///
/// Created to mitigate nonnullness of registration number (which is auto generated) by not providing it at all.
/// I've also removed any null fields because they won't be necessary here.
final class InitialRegisteredUser: Model, Content {
    static let schema = "registeredUsers"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Field(key: "name")
    var name: String

    @Field(key: "phone")
    var phone: String

    @Field(key: "email")
    var email: String

    @Field(key: "branch")
    var branch: String

    @Field(key: "gender")
    var gender: String
    
    @Timestamp(key: "date_registered", on: .create)
    var dateRegistered: Date?
    
    @Field(key: "intake_year")
    var intakeYear: Int

    init() { }

    init(id: String, name: String, phone: String, email: String, branch: String, gender: String, intakeYear: Int) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.branch = branch
        self.gender = gender
        self.intakeYear = intakeYear
    }
    
    convenience init(user: UnregisteredUser) throws {
        self.init(
            id: try user.requireID(),
            name: user.name,
            phone: user.phone,
            email: user.email,
            branch: user.branch,
            gender: user.gender,
            intakeYear: extractYearFromEmail(email: user.email) ?? 2023
        )
    }
}
