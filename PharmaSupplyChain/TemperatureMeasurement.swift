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
    
    public init() {}
    
    // MARK: Mappable
    
    public required init?(map: Map) {
        if map.JSON["temperature"] == nil || map.JSON["timestamp"] == nil {
            return nil
        }
    }
    
    public func mapping(map: Map) {
        temperature <- map["temperature"]
        timestamp <- (map["timestamp"], TransformOf<Date, Int>(fromJSON: {
            (value: Int?) -> Date? in
            
            if let value = value {
                return Date(timeIntervalSince1970: TimeInterval(value/1000))
            } else {
                return nil
            }
        }, toJSON: {
            (value: Date?) -> Int? in
            
            if let value = value {
                return Int(value.timeIntervalSince1970) * 1000
            } else {
                return nil
            }
        }))
    }
    
}
