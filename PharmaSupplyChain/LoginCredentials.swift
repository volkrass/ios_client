//
//  UserCredentials.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import SwiftyJSON

class LoginCredentials : JSONSerializable {
    
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
    
    // MARK: JSONSerializable
    
    func toJSON() -> JSON? {
        return JSON([
                    "Username" : username,
                    "Password" : password
                    ])
    }
    
    func fromJSON(object: JSON) {
        if let username = object["Username"].string {
            self.username = username
        }
        if let password = object["Password"].string {
            self.password = password
        }
    }
    
    fileprivate static func validate(username: String, password: String) -> Bool {
        return username.characters.count >= 3 && password.characters.count >= 3
    }
    
}
