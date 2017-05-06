//
//  TemperatureMeasurementsObject.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper
import CoreData

class TemperatureMeasurementsObject : Mappable, CoreDataObject {
    
    // MARK: Properties
    
    var temperatureMeasurements: [TemperatureMeasurement] = []
    var localInterpretationSuccess: Bool?
    
    public init?(timeInterval: Int, startDate: Date, measurements: [CounterBasedMeasurement], tempCategory: TemperatureCategory) {
        guard timeInterval >= 1 else {
            return nil
        }
        if measurements.isEmpty {
            localInterpretationSuccess = false
            return
        } else {
            localInterpretationSuccess = true
            for (index, measurement) in measurements.enumerated() {
                let temperatureMeasurement = TemperatureMeasurement()
                let temperature = measurement.getTemperature()
                temperatureMeasurement.temperature = temperature
                temperatureMeasurement.timestamp = startDate.addingTimeInterval(Double(index) * Double(timeInterval) * 60.0)
                if localInterpretationSuccess! {
                    if let minTemp = tempCategory.minTemp, let maxTemp = tempCategory.maxTemp {
                        localInterpretationSuccess = temperature >= Double(minTemp) && temperature <= Double(maxTemp)
                    } else {
                        localInterpretationSuccess = false
                    }
                }
                temperatureMeasurements.append(temperatureMeasurement)
            }
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
        temperatureMeasurements = object.measurements.flatMap{ TemperatureMeasurement(WithCoreDataObject: $0)}
        localInterpretationSuccess = object.localInterpretationSuccess
    }
    
    public func toCoreDataObject(object: CDTempMeasurementsObject) {
        if let moc = object.managedObjectContext {
            var cdTempMeasurements: [CDTempMeasurement] = []
            for temperatureMeasurement in temperatureMeasurements {
                if let cdTempMeasurement = NSEntityDescription.insertNewObject(forEntityName: "CDTempMeasurement", into: moc) as? CDTempMeasurement {
                    temperatureMeasurement.toCoreDataObject(object: cdTempMeasurement)
                    cdTempMeasurements.append(cdTempMeasurement)
                }
            }
            object.measurements = cdTempMeasurements
        }
        if let localInterpretationSuccess = localInterpretationSuccess {
            object.localInterpretationSuccess = localInterpretationSuccess
        }
    }
    
}
