//
//  IntakeUtil.swift
//
//
//  Created by Shrish Deshpande on 13/12/23.
//

import Foundation

func extractYearFromEmail(email: String) -> Int? {
    let components = email.components(separatedBy: "@")
    
    guard components.count == 2 else {
        return nil
    }
    
    let username = components[0]
    
    let lastTwoCharacters = String(username.suffix(2))
    
    if let year = Int(lastTwoCharacters) {
        return 2000 + year
    } else {
        return nil
    }
}
