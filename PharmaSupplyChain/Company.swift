//
//  Company.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 16.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class Company : Mappable {
    
    // MARK: Properties
    
    var id: Int?
    var name: String?
    
    /* For test purposes */
    public init() {}
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        id <- map["ID"]
        name <- map["name"]
    }
    
}
