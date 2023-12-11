import Fluent
import Vapor
import GraphQLKit

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.register(graphQLSchema: schema, withResolver: Resolver.instance)
    try app.register(collection: AuthController())
}
