//
//  TemperatureCategory.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class TemperatureCategory : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var name: String?
    var minTemp: Int?
    var maxTemp: Int?
    
    // MARK: Mappable
    
    public required init?(map: Map) {
        if map.JSON["name"] == nil || map.JSON["minTemp"] == nil || map.JSON["maxTemp"] == nil {
            return nil
        }
    }
    
    public func mapping(map: Map) {
        name <- map["name"]
        minTemp <- map["minTemp"]
        maxTemp <- map["maxTemp"]
    }
    
}
