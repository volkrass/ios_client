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
    
    func toJSON() -> Parameters? {
        return ["Username" : username as AnyObject, "Password" : password as AnyObject]
    }
    
}
