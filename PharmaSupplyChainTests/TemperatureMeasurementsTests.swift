//
//  TemperatureMeasurementsTests.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 26.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import XCTest
@testable import PharmaSupplyChain

class TemperatureMeasurementsTests : XCTestCase {
    
    func testTemperatureMeasurementsObjectInitWithInvalidTimeInterval() {
        let temperatureCategory = TemperatureCategory()
        let tempMeasurementsObject = TemperatureMeasurementsObject(timeInterval: 0, startDate: Date(), measurements: [], tempCategory: temperatureCategory)
        XCTAssertNil(tempMeasurementsObject)
    }
    
    func testTemperatureMeasurementsObjectInitWithEmptyMeasurements() {
        let temperatureCategory = TemperatureCategory()
        let tempMeasurementsObject = TemperatureMeasurementsObject(timeInterval: 5, startDate: Date(), measurements: [], tempCategory: temperatureCategory)
        XCTAssertNotNil(tempMeasurementsObject)
        XCTAssertNotNil(tempMeasurementsObject?.localInterpretationSuccess)
        XCTAssert(tempMeasurementsObject?.localInterpretationSuccess == false)
    }
    
    func testTemperatureMeasurementsObjectInitWithEmptyTempCategoryObject() {
        let temperatureCategory = TemperatureCategory()
        var measurements: [CounterBasedMeasurement] = []
        let numMeasurements = 100
        for i in 1..<numMeasurements+1 {
            let counterBasedMeasurement = CounterBasedMeasurement(temperature: UInt8(i))
            measurements.append(counterBasedMeasurement)
        }
        let startDate = Date()
        let tempMeasurementsObject = TemperatureMeasurementsObject(timeInterval: 5, startDate: startDate, measurements: measurements, tempCategory: temperatureCategory)
        XCTAssertNotNil(tempMeasurementsObject)
        XCTAssert(tempMeasurementsObject!.localInterpretationSuccess == false)
        XCTAssert(tempMeasurementsObject!.temperatureMeasurements.count == numMeasurements)
        for i in 0..<tempMeasurementsObject!.temperatureMeasurements.count {
            let counterBasedMeasurement = measurements[i]
            let measurement = tempMeasurementsObject!.temperatureMeasurements[i]
            XCTAssert(measurement.temperature == counterBasedMeasurement.getTemperature())
            let date = startDate.addingTimeInterval(Double(i) * 60.0 * 5.0)
            XCTAssert(measurement.timestamp == date)
        }
    }
    
    func testTemperatureMeasurementsObjectInitForLocalInterpretationSuccess1() {
        let temperatureCategory = TemperatureCategory()
        temperatureCategory.minTemp = 5
        temperatureCategory.maxTemp = 30
        var measurements: [CounterBasedMeasurement] = []
        let numMeasurements = 100
        for i in 1..<numMeasurements+1 {
            let counterBasedMeasurement = CounterBasedMeasurement(temperature: UInt8(i))
            measurements.append(counterBasedMeasurement)
        }
        let startDate = Date()
        let tempMeasurementsObject = TemperatureMeasurementsObject(timeInterval: 5, startDate: startDate, measurements: measurements, tempCategory: temperatureCategory)
        XCTAssertNotNil(tempMeasurementsObject)
        XCTAssert(tempMeasurementsObject!.localInterpretationSuccess == false)
        XCTAssert(tempMeasurementsObject!.temperatureMeasurements.count == numMeasurements)
        for i in 0..<tempMeasurementsObject!.temperatureMeasurements.count {
            let counterBasedMeasurement = measurements[i]
            let measurement = tempMeasurementsObject!.temperatureMeasurements[i]
            XCTAssert(measurement.temperature == counterBasedMeasurement.getTemperature())
            let date = startDate.addingTimeInterval(Double(i) * 60.0 * 5.0)
            XCTAssert(measurement.timestamp == date)
        }
    }
    
    func testTemperatureMeasurementsObjectInitForLocalInterpretationSuccess2() {
        let temperatureCategory = TemperatureCategory()
        temperatureCategory.minTemp = -5
        temperatureCategory.maxTemp = 105
        var measurements: [CounterBasedMeasurement] = []
        let numMeasurements = 100
        for i in 100..<numMeasurements+100 {
            let counterBasedMeasurement = CounterBasedMeasurement(temperature: UInt8(i))
            measurements.append(counterBasedMeasurement)
        }
        let startDate = Date()
        let tempMeasurementsObject = TemperatureMeasurementsObject(timeInterval: 5, startDate: startDate, measurements: measurements, tempCategory: temperatureCategory)
        XCTAssertNotNil(tempMeasurementsObject)
        XCTAssert(tempMeasurementsObject!.localInterpretationSuccess == true)
        XCTAssert(tempMeasurementsObject!.temperatureMeasurements.count == numMeasurements)
        for i in 0..<tempMeasurementsObject!.temperatureMeasurements.count {
            let counterBasedMeasurement = measurements[i]
            let measurement = tempMeasurementsObject!.temperatureMeasurements[i]
            XCTAssert(measurement.temperature == counterBasedMeasurement.getTemperature())
            let date = startDate.addingTimeInterval(Double(i) * 60.0 * 5.0)
            XCTAssert(measurement.timestamp == date)
        }
    }
    
}
