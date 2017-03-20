//
//  User.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 16.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class User : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var id: Int?
    var name: String?
    var role: String?
    var companyID: Int?
    var company: Company?
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        id <- map["ID"]
        name <- map["name"]
        role <- map["role"]
        companyID <- map["companyId"]
        company <- map["company"]
    }
    
}
