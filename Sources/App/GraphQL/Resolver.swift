//
//  Resolver.swift
//
//
//  Created by Shrish Deshpande on 08/12/23.
//

import Graphiti
import Vapor

final class Resolver {
  func getAllUsers(
    request: Request,
    arguments: NoArguments
  ) throws -> EventLoopFuture<[User]> {
    User.query(on: request.db).all()
  }
}
