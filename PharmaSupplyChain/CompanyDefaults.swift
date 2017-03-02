//
//  CompanyDefaults.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class CompanyDefaults : Mappable/*, CoreDataObject */ {
    
    // MARK: Properties
    
    var defaultTemperatureCategoryIndex: Int?
    var defaultMeasurementInterval: Int?
    var companyTemperatureCategories: [CompanyTemperatureCategory]?
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        defaultTemperatureCategoryIndex <- map["defaultTemperatureCategoryIndex"]
        defaultMeasurementInterval <- map["defaultMeasurementInterval"]
        companyTemperatureCategories <- map["temperatureCategories"]
    }
    
}
