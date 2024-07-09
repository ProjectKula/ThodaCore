//
//  SearchResult.swift
//
//
//  Created by Shrish Deshpande on 06/07/24.
//

import Foundation

protocol SearchResult {
    var createdAt: Date? {
        get
    }
}

extension RegisteredUser: SearchResult {
    var createdAt: Date? {
        self.dateRegistered
    }
}

extension Post: SearchResult {
}

extension Confession: SearchResult {
}
