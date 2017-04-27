//
//  Sensor.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class Sensor : Mappable {
    
    // MARK: Properties
    
    var sensorMAC: String?
    var tempCategory: TemperatureCategory?
    
    public init() {}
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        sensorMAC <- map["sensorUUID"]
        tempCategory <- map["tempCategory"]
    }
    
}
