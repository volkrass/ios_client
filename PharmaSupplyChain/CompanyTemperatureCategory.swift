//
//  CompanyTemperatureCategory.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

/* Duplication of TemperatureCategory. Caused by http://dev.modum.io/api/v1/company/defaults and http://dev.modum.io/api/preparedshipments/tntnumber/<tntNumber> returning TemperatureCateogory in different format */
class CompanyTemperatureCategory : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var label: String?
    var name: String?
    var tempLow: Int?
    var tempHigh: Int?
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        label <- map["label"]
        name <- map["value.name"]
        tempLow <- map["value.tempLow"]
        tempHigh <- map["value.tempHigh"]
    }
    
}
