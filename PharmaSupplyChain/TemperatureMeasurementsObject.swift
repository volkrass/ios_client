//
//  TemperatureMeasurementsObject.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class TemperatureMeasurementsObject : Mappable, CoreDataObject {
    
    // MARK: Properties
    
    var temperatureMeasurements: [TemperatureMeasurement] = []
    var localInterpretationSuccess: Bool?
    
    public init?(timeInterval: Int, startDate: Date, measurements: [CounterBasedMeasurement], tempCategory: TemperatureCategory) {
        guard timeInterval >= 1 else {
            return nil
        }
        localInterpretationSuccess = true
        for (index, measurement) in measurements.enumerated() {
            let temperatureMeasurement = TemperatureMeasurement()
            let temperature = measurement.getTemperature()
            temperatureMeasurement.temperature = temperature
            temperatureMeasurement.timestamp = startDate.addingTimeInterval(Double(index+1) * Double(timeInterval) * 60.0)
            if let minTemp = tempCategory.minTemp, let maxTemp = tempCategory.maxTemp, temperature > Double(maxTemp) || temperature < Double(minTemp) {
                localInterpretationSuccess = false
            }
            temperatureMeasurements.append(temperatureMeasurement)
        }
    }
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        temperatureMeasurements <- map["measurements"]
        localInterpretationSuccess <- map["localInterpretationSuccess"]
    }
    
    // MARK: CoreDataObject
    
    public required init?(WithCoreDataObject object: CDTempMeasurementsObject) {
        
    }
    
    public func toCoreDataObject(object: CDTempMeasurementsObject) {
        
    }
    
}
