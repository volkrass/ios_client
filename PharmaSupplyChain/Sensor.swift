//
//  Sensor.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class Sensor : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var sensorMAC: String?
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        sensorMAC <- map["sensorUUID"]
    }
    
}
