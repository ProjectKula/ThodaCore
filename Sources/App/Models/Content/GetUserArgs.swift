//
//  GetUserArgs.swift
//  
//
//  Created by Shrish Deshpande on 11/12/23.
//

import Fluent
import Vapor

struct GetUserArgs: Content {
    let id: String
    let email: String
}
