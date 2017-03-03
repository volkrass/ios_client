//
//  LoginObject.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class LoginObject : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var expire: Date?
    var token: String?
    
    // MARK: Mappable
    
    public required init?(map: Map) {
        if map.JSON["expire"] == nil || map.JSON["token"] == nil {
            return nil
        }
    }
    
    public func mapping(map: Map) {
        expire <- (map["expire"], ISO8601DateTransform())
        token <- map["token"]
    }
    
}
