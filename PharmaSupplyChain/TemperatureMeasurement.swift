//
//  TemperatureMeasurement.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class TemperatureMeasurement : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var temperature: Double?
    var timestamp: Date?
    
    // MARK: Mappable
    
    public required init?(map: Map) {
        if map.JSON["temperature"] == nil || map.JSON["timestamp"] == nil {
            return nil
        }
    }
    
    public func mapping(map: Map) {
        temperature <- map["name"]
        timestamp <- (map["minTemp"], DateTransform())
    }
    
}
