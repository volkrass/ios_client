//
//  ModumSensor.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

@objc protocol ModumSensorDelegate {
    
    func modumSensorIsReady()
    func modumSensorServiceUnsupported()
    func modumSensorIsBroken()
    
    @objc optional func modumSensorBatteryLevelReceived(_ batteryLevel: Int)
    
    @objc optional func modumSensorContractIDReceived(_ contractID: String)
    @objc optional func modumSensorContractIDWritten(_ success: Bool)
    
    @objc optional func modumSensorIsRecordingFlagReceived(_ isRecording: Bool)
    @objc optional func modumSensorIsRecordingFlagWritten(_ success: Bool)
    
    @objc optional func modumSensorRecordingTimeIntervalReceived(_ recordingTimeInterval: Date)
    @objc optional func modumSensorRecordingTimeIntervalWritten(_ success: Bool)
    
    @objc optional func modumSensorStartTimeReceived(_ startTime: Date)
    @objc optional func modumSensorStartTimeWritten(_ success: Bool)
    
    @objc optional func modumSensorMeasurementsCountReceived(_ measurementsCount: Int)
    
    @objc optional func modumSensorMeasurementsReadIndexReceived(_ measurementsReadIndex: Int)
    @objc optional func modumSensorMeasurementsReadIndexWritten(_ success: Bool)
    
}

class ModumSensor : NSObject, CBPeripheralDelegate {
    
    // MARK: Properties
    
    var delegate: ModumSensorDelegate?
    
    fileprivate var sensor: CBPeripheral
    
    /* Helper variables */
    fileprivate var charsForBatteryLevelServiceDiscovered: Bool = false
    fileprivate var charsForSensorServiceDiscovered: Bool = false
    
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
    
    func requestBatteryLevel() {
        if let batteryLevelCharacteristic = batteryLevelCharacteristic {
            sensor.readValue(for: batteryLevelCharacteristic)
        }
    }
    
    func requestContractID() {
        if let contractIDCharacteristic = contractIDCharacteristic {
            sensor.readValue(for: contractIDCharacteristic)
        }
    }
    
    func requestIsRecording() {
        if let isRecordingCharacteristic = isRecordingCharacteristic {
            sensor.readValue(for: isRecordingCharacteristic)
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
                if let delegate = delegate {
                    delegate.modumSensorContractIDWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write contract ID: \(error.localizedDescription)")
                }
            case isRecordingUUID:
                if let delegate = delegate {
                    delegate.modumSensorIsRecordingFlagWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write isRecording flag: \(error.localizedDescription)")
                }
            case startTimeUUID:
                if let delegate = delegate {
                    delegate.modumSensorStartTimeWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write startTime: \(error.localizedDescription)")
                }
            case recordingTimeIntervalUUID:
                if let delegate = delegate {
                    delegate.modumSensorRecordingTimeIntervalWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write timeInterval: \(error.localizedDescription)")
                }
            case measurementsReadIndexUUID:
                if let delegate = delegate {
                    delegate.modumSensorMeasurementsReadIndexWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write measurements read index: \(error.localizedDescription)")
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
                    delegate.modumSensorBatteryLevelReceived?(Int(batteryLevelValue[0]))
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
                    if let contractID = String(data: contractIDData, encoding: .utf8) {
                        delegate.modumSensorContractIDReceived?(contractID)
                    }
                }
            case isRecordingUUID:
                if let delegate = delegate, let isRecordingValue = characteristic.value, !isRecordingValue.isEmpty {
                    let isRecording: UInt8 = isRecordingValue[0]
                    if isRecording == 0xFF {
                        delegate.modumSensorIsBroken()
                    } else {
                        if isRecording == 0x01 {
                            delegate.modumSensorIsRecordingFlagReceived?(true)
                        } else if isRecording == 0x00 {
                            delegate.modumSensorIsRecordingFlagReceived?(false)
                        } else {
                            log("Unknown value for isRecording flag: \(isRecording)")
                        }
                    }
                }
            default:
                break
        }
    }
    
    // MARK: Characteristics Interaction
    
    fileprivate func writeContractId(_ contractID: String) {
        guard let contractIDCharacteristic = contractIDCharacteristic else {
            log("No contract ID characteristic with UUID: \(contractIDUUID)")
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
            return
        }
        
        let isRecordingValue: Data = isRecording ? Data(bytes: [0x01] as [UInt8]) : Data(bytes: [0x00] as [UInt8])
        sensor.writeValue(isRecordingValue, for: isRecordingCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeStartTime(_ startTime: Date) {
        guard let startTimeCharacteristic = startTimeCharacteristic else {
            log("No startTime characteristic with UUID: \(startTimeUUID)")
            return
        }
        
        let startTimeBytes = toByteArray(startTime.timeIntervalSince1970 * 1000.0)
        let startTimeData = Data(bytes: startTimeBytes)
        sensor.writeValue(startTimeData, for: startTimeCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeRecordingTimeInterval(_ timeInterval: UInt8) {
        guard let recordingTimeIntervalCharacteristic = recordingTimeIntervalCharacteristic else {
            log("No recordingTimeInterval characteristic with UUID: \(recordingTimeIntervalUUID)")
            return
        }
        
        let timeIntervalData = Data(bytes: [timeInterval])
        sensor.writeValue(timeIntervalData, for: recordingTimeIntervalCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeMeasurementsIndex() {
        guard let measurementsReadIndexCharacteristic = measurementsReadIndexCharacteristic else {
            log("No measurements read index characteristic with UUID: \(measurementsReadIndexUUID)")
            return
        }
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
