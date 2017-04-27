//
//  SmartContractStatus.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class SmartContractStatus : Mappable {
    
    // MARK: Properties
    
    var isMined: Bool?
    
    // MARK: Mappable
    
    public required init?(map: Map) {
        if map.JSON["isMined"] == nil {
            return nil
        }
    }
    
    public func mapping(map: Map) {
        isMined <- map["isMined"]
    }
    
}
