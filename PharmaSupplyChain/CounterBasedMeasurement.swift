//
//  CounterBasedMeasurement.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 23.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

/* Represents temperature measurement that has been read out from sensor */
class CounterBasedMeasurement {
    
    // MARK: Properties
    
    fileprivate var temperature: Double
    
    // MARK: Public function
    
    init(temperature: UInt8) {
        self.temperature = CounterBasedMeasurement.decodeTemp(temperature: temperature)
    }
    
    func getTemperature() -> Double {
        return temperature
    }
    
    public static func measurementsFromData(data: Data) -> [CounterBasedMeasurement] {
        guard !data.isEmpty else {
            return []
        }
        var measurements: [CounterBasedMeasurement] = []
        for byte in data {
            measurements.append(CounterBasedMeasurement(temperature: byte))
        }
        return measurements
    }
    
    // MARK: Helper functions
    
    fileprivate static func unsignedConversion(value: UInt8) -> Int {
        var val = Int(value)
        if val < 0 {
            val += 0x100
        }
        return val
    }
    
    fileprivate static func decodeTemp(temperature: UInt8) -> Double {
        let factor = 60.0 / Double(0xff)
        return Double(unsignedConversion(value: temperature)) * factor - 10;
    }
    
}
