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
    
    func testTemperatureMeasurementsObjectInitWithUnorderedMeasurements() {
        let temperatureCategory = TemperatureCategory()
        let tempMeasurementsObject = TemperatureMeasurementsObject(timeInterval: 5, startDate: Date(), measurements: [], tempCategory: temperatureCategory)
    }
}
