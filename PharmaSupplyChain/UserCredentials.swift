//
//  UserCredentials.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Alamofire

struct UserCredentials : JSONSerializable {
    var username: String
    var password: String
    
    init?(username: String, password: String) {
        if UserCredentials.validate(username: username, password: password) {
            self.username = username
            self.password = password
        } else {
            return nil
        }
    }
    
    func toJSON() -> Parameters? {
        return ["Username" : username as AnyObject, "Password" : password as AnyObject]
    }
    
    fileprivate static func validate(username: String, password: String) -> Bool {
        return username.characters.count >= 3 && password.characters.count >= 3
    }
    
}
