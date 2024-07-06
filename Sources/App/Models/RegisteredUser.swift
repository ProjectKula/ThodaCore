//
//  RegisteredUser.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Vapor
import Fluent
import FluentPostgresDriver

public final class RegisteredUser: Model, Content, PostgresDecodable {
    public static let schema = "registeredUsers"

    /// The user's ID
    @ID(custom: "id", generatedBy: .user)
    public var id: Int?
    
    /// The user's college ID
    @Parent(key: "collegeid")
    var collegeId: UnregisteredUser

    /// The user's name
    @Field(key: "name")
    var name: String

    /// The user's phone number
    @Field(key: "phone")
    var phone: String

    /// The user's college email address
    @Field(key: "email")
    var email: String
    
    /// The user's personal email address
    @OptionalField(key: "personal_email")
    var personalEmail: String?

    /// The user's branch of study - ME, EC, AS, CV, BT, etc
    @Field(key: "branch")
    var branch: String

    /// The user's gender - M, F or X (unspecified)
    @Field(key: "gender")
    var gender: String
    
    /// The user's pronouns
    @OptionalField(key: "pronouns")
    var pronouns: String?
    
    /// The date the user registered
    @Timestamp(key: "date_registered", on: .create)
    var dateRegistered: Date?
    
    /// The user's one-line bio
    @OptionalField(key: "bio")
    var bio: String?
    
    /// The year the user joined the college
    @Field(key: "intake_year")
    var intakeYear: Int
    
    /// The user's avatar hash (stored in R2)
    @Field(key: "avatar_hash")
    var avatarHash: String?
    
    /// List of posts this user has created
    @Children(for: \.$creator)
    var posts: [Post]
    
    /// List of posts this user has liked
    @Siblings(through: LikedPost.self, from: \.$user, to: \.$post)
    var likedPosts: [Post]
    
    /// List of users who are following this user
    @Siblings(through: Follower.self, from: \.$followed, to: \.$follower)
    var followers: [RegisteredUser]
    
    /// List of users this user is following
    @Siblings(through: Follower.self, from: \.$follower, to: \.$followed)
    var following: [RegisteredUser]

    /// List of confessions this user has liked
    @Siblings(through: LikedConfession.self, from: \.$user, to: \.$confession)
    var likedConfessions: [Confession]

    /// List of notifications
    @Children(for: \.$targetUser)
    var notifications: [Notification]

    /// List of badges
    @Children(for: \.$user)
    var badges: [Badge]

    public init() { }

    public init(collegeId: String, name: String, phone: String, email: String, personalEmail: String? = nil, branch: String, gender: String, pronouns: String? = nil, bio: String? = nil, intakeYear: Int, id: Int? = nil) {
        self.$collegeId.id = collegeId
        self.name = name
        self.phone = phone
        self.email = email
        self.personalEmail = personalEmail
        self.branch = branch
        self.gender = gender
        self.pronouns = pronouns
        self.bio = bio
        self.intakeYear = intakeYear
        self.id = id
    }
}
