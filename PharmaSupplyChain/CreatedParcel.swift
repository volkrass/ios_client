//
//  CreatedParcel.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 26.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class CreatedParcel : Mappable {
    
    // MARK: Properties
    
    var tntNumber: String?
    var sensorUUID: String?
    var tempCategory: TemperatureCategory?
    var maxFailsTemp: Int?
    
    public init() {}
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        tntNumber <- map["tntNumber"]
        sensorUUID <- map["sensorUUID"]
        tempCategory <- map["tempCategory"]
        maxFailsTemp <- map["maxFailsTemp"]
    }
    
}
