//
//  User.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "usn")
    var usn: String

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

    init() { }

    init(id: UUID? = nil, usn: String, name: String, phone: String, email: String, branch: String, gender: String) {
        self.id = id
        self.usn = usn
        self.name = name
        self.phone = phone
        self.email = email
        self.branch = branch
        self.gender = gender
    }
}
