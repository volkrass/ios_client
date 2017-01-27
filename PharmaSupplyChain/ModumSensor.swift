//
//  ModumSensor.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol ModumSensorDelegate {
    
    func modumSensorIsReady()
    func modumSensorServiceUnsupported()
    func modumSensorErrorOccured(_ error: SensorError?)
    func modumSensorCheckBeforeSendingPerformed()
    func modumSensorCheckBeforeReceivingPerformed()
    func modumSensorShipmentDataWritten()
    func modumSensorShipmentDataReceived()
}

enum SensorError: Error {
    case batteryLevelTooLow
    case recordingAlready
    case selfCheckFailed
    case serviceUnavailable
}

class ModumSensor : NSObject, CBPeripheralDelegate {
    
    // MARK: Properties
    
    var delegate: ModumSensorDelegate?
    
    fileprivate var sensor: CBPeripheral
    
    /* Helper variables */
    fileprivate var charsForBatteryLevelServiceDiscovered: Bool = false
    fileprivate var charsForSensorServiceDiscovered: Bool = false
    
    /* Helper variables for performing sensor self check */
    fileprivate var isPerformingCheckBeforeSending: Bool = false
    fileprivate var discoveredBatteryLevel: Bool = false
    fileprivate var discoveredIsRecording: Bool = false
    
    /* Helper variables for writing shipment data */
    fileprivate var isWritingShipmentData: Bool = false
    fileprivate var didWriteContractID: Bool = false
    fileprivate var didWriteStartTime: Bool = false
    fileprivate var didWriteTimeInterval: Bool = false
    fileprivate var didWriteIsRecording: Bool = false
    
    /* Helper variables for reading out temperature measurements */
    fileprivate var measurementsCount: UInt32?
    fileprivate var measurementsIndex: UInt32?
    
    /**********  Characteristics **********/
    
    fileprivate var batteryLevelCharacteristic: CBCharacteristic?
    fileprivate var contractIDCharacteristic: CBCharacteristic?
    fileprivate var startTimeCharacteristic: CBCharacteristic?
    fileprivate var measurementsCharacteristic: CBCharacteristic?
    fileprivate var measurementsCountCharacteristic: CBCharacteristic?
    fileprivate var measurementsReadIndexCharacteristic: CBCharacteristic?
    fileprivate var recordingTimeIntervalCharacteristic: CBCharacteristic?
    fileprivate var isRecordingCharacteristic: CBCharacteristic?
    
    // MARK: Constants
    
    /* sensor should have at least 30% of battery before sending process */
    fileprivate let MIN_BATTERY_LEVEL: Int = 30
    
    /**********  Services UUIDs **********/
    
    fileprivate let batteryLevelServiceUUID: CBUUID = CBUUID(string: "0000180f-0000-1000-8000-00805f9b34fb")
    fileprivate let sensorServiceUUID: CBUUID = CBUUID(string: "f000aa00-0451-4000-b000-000000000000")
    
    /********** Characteristics UUIDs **********/
    
    /* sensor battery level characterstic UUID, in % */
    fileprivate let batteryLevelUUID: CBUUID = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb")
    
    /* characteristic from where the actual measurements are read */
    fileprivate let measurementsUUID: CBUUID = CBUUID(string: "f000aa01-0451-4000-b000-000000000000")
    
    /* characteristic determining whether sensor is currently recording */
    fileprivate let isRecordingUUID: CBUUID = CBUUID(string: "f000aa02-0451-4000-b000-000000000000")
    
    /* characteristic determining how often sensor takes measurements (in <units>)*/
    fileprivate let recordingTimeIntervalUUID: CBUUID = CBUUID(string: "f000aa03-0451-4000-b000-000000000000")
    
    /* characteristic determining how many temperature measurements are there (in <units>) */
    fileprivate let measurementsCountUUID: CBUUID = CBUUID(string: "f000aa04-0451-4000-b000-000000000000")
    
    /* characteristic determining the index to the temperature measurements array */
    fileprivate let measurementsReadIndexUUID: CBUUID = CBUUID(string: "f000aa05-0451-4000-b000-000000000000")
    
    /* smart contract ID characteristic UUID */
    fileprivate let contractIDUUID: CBUUID = CBUUID(string: "f000aa06-0451-4000-b000-000000000000")
    
    /* characteristic determining the start time of recording */
    fileprivate let startTimeUUID: CBUUID = CBUUID(string: "f000aa07-0451-4000-b000-000000000000")
    
    init(WithPeripheral peripheral: CBPeripheral) {
        sensor = peripheral

        super.init()
        
        sensor.delegate = self
    }
    
    // MARK: Public functions
    
    func start() {
        if let services = sensor.services, !services.isEmpty {
            let serviceUUIDs = services.map {$0.uuid}
            guard serviceUUIDs.contains(Array: [batteryLevelServiceUUID, sensorServiceUUID]) else {
                log("Given peripheral \(sensor.description) doesn't expose required services.")
                if let delegate = delegate {
                    delegate.modumSensorServiceUnsupported()
                }
                return
            }
            for service in services {
                switch service.uuid {
                    case batteryLevelServiceUUID:
                        sensor.discoverCharacteristics([batteryLevelUUID], for: service)
                    case sensorServiceUUID:
                        sensor.discoverCharacteristics([measurementsUUID, isRecordingUUID, recordingTimeIntervalUUID, measurementsCountUUID, measurementsReadIndexUUID, contractIDUUID, startTimeUUID], for: service)
                    default:
                        break
                }
            }
        } else {
            sensor.discoverServices([batteryLevelServiceUUID, sensorServiceUUID])
        }
    }
    
    /*
     Assures that the sensor battery level is sufficient and whether sensor isn't recording before initializing send operation
     */
    func performSensorCheckBeforeSending() {
        isPerformingCheckBeforeSending = true
        if let batteryLevelCharacteristic = batteryLevelCharacteristic, let isRecordingCharacteristic = isRecordingCharacteristic {
            sensor.readValue(for: batteryLevelCharacteristic)
            sensor.readValue(for: isRecordingCharacteristic)
        } else {
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
        }
    }
    
    /*
     Assure that sensor is recording before downloading shipment datas
     */
    func performSensorCheckBeforeReceiving() {
        if let isRecordingCharacteristic = isRecordingCharacteristic {
            sensor.readValue(for: isRecordingCharacteristic)
        } else {
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
        }
    }
    
    /*
     Writes data for the shipment into the sensor
     */
    func writeShipmentData(startTime: Date, timeInterval: UInt8, contractID: String) {
        writeStartTime(startTime)
        writeContractId(contractID)
        writeRecordingTimeInterval(timeInterval)
        writeIsRecording(true)
    }
    
    /*
     Downloads data related to the shipment from the sensor
     */
    func downloadShipmentData() {
        if let startTimeCharacteristic = startTimeCharacteristic, let recordingTimeIntervalCharacteristic = recordingTimeIntervalCharacteristic, let measurementsCountCharacteristic = measurementsCountCharacteristic {
            writeIsRecording(false)
            sensor.readValue(for: measurementsCountCharacteristic)
            sensor.readValue(for: startTimeCharacteristic)
            sensor.readValue(for: recordingTimeIntervalCharacteristic)
        } else {
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
        }
    }
    
    // MARK: CBPeriperhalDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            log("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard peripheral == sensor else {
            log("Discovered services for wrong peripheral \(peripheral.name)")
            return
        }
        
        if let services = peripheral.services, !services.isEmpty {
            let servicesUUIDs = services.map {$0.uuid}
            guard servicesUUIDs.contains(Array: [batteryLevelServiceUUID, sensorServiceUUID]) else {
                log("Given peripheral \(sensor.description) doesn't expose required services.")
                if let delegate = delegate {
                    delegate.modumSensorServiceUnsupported()
                }
                return
            }
            
            for service in services {
                switch service.uuid {
                    case batteryLevelServiceUUID:
                        sensor.discoverCharacteristics([batteryLevelUUID], for: service)
                    case sensorServiceUUID:
                        sensor.discoverCharacteristics([measurementsUUID, isRecordingUUID, recordingTimeIntervalUUID, measurementsCountUUID, measurementsReadIndexUUID, contractIDUUID, startTimeUUID], for: service)
                    default:
                        break
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            log("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        guard peripheral == sensor else {
            log("Discovered service characteristics for wrong peripheral \(peripheral.name)")
            return
        }
        guard service.uuid == sensorServiceUUID || service.uuid == batteryLevelServiceUUID else {
            log("Discovered characteristics for wrong service \(service.description)")
            return
        }
        
        if service.uuid == batteryLevelServiceUUID {
            charsForBatteryLevelServiceDiscovered = true
        } else if service.uuid == sensorServiceUUID {
            charsForSensorServiceDiscovered = true
        }
        
        if let characteristics = service.characteristics {
            characteristics.forEach({
                characteristic in
                
                switch characteristic.uuid {
                    case batteryLevelUUID:
                        batteryLevelCharacteristic = characteristic
                    case recordingTimeIntervalUUID:
                        recordingTimeIntervalCharacteristic = characteristic
                    case contractIDUUID:
                        contractIDCharacteristic = characteristic
                    case measurementsUUID:
                        measurementsCharacteristic = characteristic
                    case measurementsCountUUID:
                        measurementsCountCharacteristic = characteristic
                    case measurementsReadIndexUUID:
                        measurementsReadIndexCharacteristic = characteristic
                    case isRecordingUUID:
                        isRecordingCharacteristic = characteristic
                    case startTimeUUID:
                        startTimeCharacteristic = characteristic
                    default:
                        break
                }
            })
        }
        
        if let delegate = delegate, (charsForSensorServiceDiscovered && charsForBatteryLevelServiceDiscovered) {
            if allCharacteriticsDiscovered() {
                delegate.modumSensorIsReady()
            } else {
                delegate.modumSensorServiceUnsupported()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral == sensor else {
            log("Received write indication for wrong peripheral \(peripheral.name)")
            return
        }
        guard characteristic.service.uuid == sensorServiceUUID || characteristic.service.uuid == batteryLevelServiceUUID else {
            log("Received write indication for wrong service \(characteristic.service.description)")
            return
        }
        
        switch characteristic.uuid {
            case contractIDUUID:
                if let error = error {
                    log("Failed to write contract ID: \(error.localizedDescription)")
                }
            case isRecordingUUID:
                if let error = error {
                    log("Failed to write isRecording flag: \(error.localizedDescription)")
                }
            case startTimeUUID:
                if let error = error {
                    log("Failed to write startTime: \(error.localizedDescription)")
                }
            case recordingTimeIntervalUUID:
                if let error = error {
                    log("Failed to write timeInterval: \(error.localizedDescription)")
                }
            case measurementsReadIndexUUID:
                if let error = error {
                    log("Failed to write measurements read index: \(error.localizedDescription)")
                } else {
                    if let measurementsCharacteristic = measurementsCharacteristic {
                        sensor.readValue(for: measurementsCharacteristic)
                    }
                }
            default:
                break
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            log("Error updating value for characteristic: \(characteristic.description)")
            return
        }
        guard peripheral == sensor else {
            log("Updated value for characteristic on wrong peripheral: \(peripheral.name)")
            return
        }
        guard characteristic.service.uuid == sensorServiceUUID || characteristic.service.uuid == batteryLevelServiceUUID else {
            log("Updated characteristic value for wrong service: \(characteristic.service.description)")
            return
        }
        
        switch characteristic.uuid {
            case batteryLevelUUID:
                if let delegate = delegate, let batteryLevelValue = characteristic.value, !batteryLevelValue.isEmpty {
                    let batteryLevel = Int(batteryLevelValue[0])
                    if isPerformingCheckBeforeSending {
                        if batteryLevel <= MIN_BATTERY_LEVEL {
                           delegate.modumSensorErrorOccured(.batteryLevelTooLow)
                            discoveredIsRecording = false
                            discoveredBatteryLevel = false
                            isPerformingCheckBeforeSending = false
                        } else {
                            discoveredBatteryLevel = true
                        }
                        if discoveredBatteryLevel && discoveredIsRecording {
                            delegate.modumSensorCheckBeforeSendingPerformed()
                            discoveredIsRecording = false
                            discoveredBatteryLevel = false
                            isPerformingCheckBeforeSending = false
                        }
                    }
                }
            case contractIDUUID:
                if let delegate = delegate, let contractIDValue = characteristic.value, !contractIDValue.isEmpty {
                    /* handling zero-terminated string */
                    var contractIDBytes: [UInt8] = []
                    for byte in contractIDValue {
                        if byte != 0 {
                            contractIDBytes.append(byte)
                        } else {
                            break
                        }
                    }
                    let contractIDData = Data(bytes: contractIDBytes)
                    let contractID = String(data: contractIDData, encoding: .utf8)
//                    if let contractID = String(data: contractIDData, encoding: .utf8) {
//                        delegate.modumSensorContractIDReceived?(contractID)
//                    }
                }
            case isRecordingUUID:
                if let delegate = delegate, let isRecordingValue = characteristic.value, !isRecordingValue.isEmpty {
                    let isRecording: UInt8 = isRecordingValue[0]
                    if isRecording == 0xFF {
                        delegate.modumSensorErrorOccured(.selfCheckFailed)
                    } else if isRecording == 0x01 {
                        if isPerformingCheckBeforeSending {
                            delegate.modumSensorErrorOccured(SensorError.recordingAlready)
                            discoveredIsRecording = false
                            discoveredBatteryLevel = false
                            isPerformingCheckBeforeSending = false
                        }
                    } else if isRecording == 0x00 {
                        if isPerformingCheckBeforeSending {
                            discoveredIsRecording = true
                            if discoveredIsRecording && discoveredBatteryLevel {
                                delegate.modumSensorCheckBeforeSendingPerformed()
                                discoveredIsRecording = false
                                discoveredBatteryLevel = false
                                isPerformingCheckBeforeSending = false
                            }
                        }
                    }
//                        if isRecording == 0x01 {
//                            delegate.modumSensorIsRecordingFlagReceived?(true)
//                        } else if isRecording == 0x00 {
//                            delegate.modumSensorIsRecordingFlagReceived?(false)
//                        } else {
//                            log("Unknown value for isRecording flag: \(isRecording)")
//                        }
                }
            case measurementsCountUUID:
                if let measurementsCountValue = characteristic.value, !measurementsCountValue.isEmpty {
                    measurementsCount = UInt32(littleEndian: measurementsCountValue.withUnsafeBytes { $0.pointee })
                    measurementsIndex = 0
                    
                    /* DEBUG */
                    log("Measurements count: \(measurementsCount)")
                    /* DEBUG */
                    
                    if measurementsCount! > 0 {
                        writeMeasurementsIndex(measurementsIndex!)
                    }
            }
            case measurementsUUID:
                if let measurementsValue = characteristic.value, !measurementsValue.isEmpty {
                    if let temperatureMeasurements = TemperatureMeasurement.fromData(measurementsValue) {
                        
                    }
                }
                break
            default:
                break
        }
    }
    
    // MARK: Characteristics Interaction
    
    fileprivate func writeContractId(_ contractID: String) {
        guard let contractIDCharacteristic = contractIDCharacteristic else {
            log("No contract ID characteristic with UUID: \(contractIDUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        if var contractIDData = contractID.data(using: .utf8) {
            contractIDData.append(0)
            
            sensor.writeValue(contractIDData, for: contractIDCharacteristic, type: .withResponse)
        }
    }
    
    fileprivate func writeIsRecording(_ isRecording: Bool) {
        guard let isRecordingCharacteristic = isRecordingCharacteristic else {
            log("No isRecording characteristic with UUID: \(isRecordingUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        let isRecordingValue: Data = isRecording ? Data(bytes: [0x01] as [UInt8]) : Data(bytes: [0x00] as [UInt8])
        sensor.writeValue(isRecordingValue, for: isRecordingCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeStartTime(_ startTime: Date) {
        guard let startTimeCharacteristic = startTimeCharacteristic else {
            log("No startTime characteristic with UUID: \(startTimeUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        let startTimeBytes = toByteArray(startTime.timeIntervalSince1970 * 1000.0)
        let startTimeData = Data(bytes: startTimeBytes)
        sensor.writeValue(startTimeData, for: startTimeCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeRecordingTimeInterval(_ timeInterval: UInt8) {
        guard let recordingTimeIntervalCharacteristic = recordingTimeIntervalCharacteristic else {
            log("No recordingTimeInterval characteristic with UUID: \(recordingTimeIntervalUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        let timeIntervalData = Data(bytes: [timeInterval])
        sensor.writeValue(timeIntervalData, for: recordingTimeIntervalCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeMeasurementsIndex(_ index: UInt32) {
        guard let measurementsReadIndexCharacteristic = measurementsReadIndexCharacteristic else {
            log("No measurements read index characteristic with UUID: \(measurementsReadIndexUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        var readoutIndex = UInt32(littleEndian: index)
        let readoutIndexData = Data(buffer: UnsafeBufferPointer(start: &readoutIndex, count: MemoryLayout<UInt32>.size))
        sensor.writeValue(readoutIndexData, for: measurementsReadIndexCharacteristic, type: .withResponse)
    }
    
    // MARK: Helper functions
    
    fileprivate func allCharacteriticsDiscovered() -> Bool {
        return contractIDCharacteristic         != nil &&
            startTimeCharacteristic             != nil &&
            batteryLevelCharacteristic          != nil &&
            measurementsCharacteristic          != nil &&
            measurementsCountCharacteristic     != nil &&
            measurementsReadIndexCharacteristic != nil &&
            recordingTimeIntervalCharacteristic != nil &&
            isRecordingCharacteristic           != nil
    }
    
}
