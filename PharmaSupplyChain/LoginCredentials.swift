//
//  UserCredentials.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

class LoginCredentials {
    
    // MARK: Properties
    
    fileprivate var username: String
    fileprivate var password: String
    
    // MARK: Initializers
    
    init() {
        username = ""
        password = ""
    }
    
    init?(username: String, password: String) {
        if LoginCredentials.validate(username: username, password: password) {
            self.username = username
            self.password = password
        } else {
            return nil
        }
    }
    
    fileprivate static func validate(username: String, password: String) -> Bool {
        return username.characters.count >= 3 && password.characters.count >= 3
    }
    
}
