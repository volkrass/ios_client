//
//  Measurement.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 26.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

class TemperatureMeasurement {
    
    // MARK: Properties
    
    fileprivate var timestamp: UInt16
    fileprivate var temperature: Double
    
    init(WithTimestamp timestamp: UInt16, WithTemperature temperature: Double) {
        self.timestamp = timestamp
        self.temperature = temperature
    }
    
    static func fromData(_ data: Data) -> [TemperatureMeasurement]? {
        var temperatureMeasurements: [TemperatureMeasurement]?
        let byteArray = data.withUnsafeBytes { [UInt8](UnsafeBufferPointer(start: $0, count: data.count)) }
        for index in stride(from: 0, to: byteArray.count, by: 4) {
            if let timestamp = getTimestamp(byteArray, index), let temperature = getTemperature(byteArray, index+2) {
                if temperatureMeasurements == nil {
                    temperatureMeasurements = []
                }
                let temperatureMeasurement = TemperatureMeasurement(WithTimestamp: timestamp, WithTemperature: temperature)
                temperatureMeasurements!.append(temperatureMeasurement)
            }
        }
        return temperatureMeasurements
    }
    
    // MARK: Helper functions
    
    fileprivate static func getTimestamp(_ array: [UInt8], _ offset: Int) -> UInt16? {
        return getShort(FromByteArray: array, AtOffset: offset)
    }
    
    fileprivate static func getTemperature(_ array: [UInt8], _ offset: Int) -> Double? {
        if let temperatureValueShort = getShort(FromByteArray: array, AtOffset: offset) {
            var temperatureValue = Int(temperatureValueShort)
            if temperatureValue < 0 {
                temperatureValue += 0x10000
            }
            let factor: Double = 60.0/0x10000
            return Double(temperatureValue)*factor - 10
        } else {
            return nil
        }
    }
    
    
    fileprivate static func getShort(FromByteArray array: [UInt8], AtOffset offset: Int) -> UInt16? {
        guard offset >= 0 && offset + 1 < array.count else {
            return nil
        }
        let lowerByte = Int(array[offset] & 0xFF)
        let upperByte = Int(array[offset+1] & 0xFF)
        return UInt16((upperByte << 8) + lowerByte)
    }
}
