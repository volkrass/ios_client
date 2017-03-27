//
//  TemperatureCategory.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class TemperatureCategory : Mappable, CoreDataObject {
    
    // MARK: Properties
    
    var name: String?
    var minTemp: Int?
    var maxTemp: Int?
    
    public init() {}
    
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
    
    // MARK: CoreDataObject
    
    public required init?(WithCoreDataObject object: CDTempCategory) {
        name = object.name
        minTemp = object.minTemp
        maxTemp = object.maxTemp
    }
    
    public func toCoreDataObject(object: CDTempCategory) {
        if let name = name, let minTemp = minTemp, let maxTemp = maxTemp {
            object.name = name
            object.minTemp = minTemp
            object.maxTemp = maxTemp
        }
    }
    
}
