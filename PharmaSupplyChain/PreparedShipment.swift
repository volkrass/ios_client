//
//  PreparedShipment.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class PreparedShipment : Mappable {
    
    // MARK: Properties
    
    var senderCompanyName: String?
    var receiverCompanyName: String?
    var tntNumber: String?
    var temperatureCategory: TemperatureCategory?
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        senderCompanyName <- map["senderCompanyName"]
        receiverCompanyName <- map["receiverCompanyName"]
        tntNumber <- map["tntNumber"]
        temperatureCategory <- map["temperatureCategory"]
    }
    
}
