//
//  SensorService.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 11.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

@objc protocol SensorServiceDelegate {
    
    func sensorServiceIsReady()
    func sensorServiceIsBroken()
    
    @objc optional func contractIDReceived(_ contractID: String)
    @objc optional func contractIDWritten(_ success: Bool)
    
    @objc optional func isRecordingFlagReceived(_ isRecording: Bool)
    @objc optional func isRecordingFlagWritten(_ success: Bool)
    
    @objc optional func recordingTimeIntervalReceived(_ recordingTimeInterval: Date)
    @objc optional func recordingTimeIntervalWritten(_ success: Bool)
    
    @objc optional func startTimeReceived(_ startTime: Date)
    @objc optional func startTimeWritten(_ success: Bool)
    
    @objc optional func measurementsCountReceived(_ measurementsCount: Int)
    
    @objc optional func measurementsReadIndexReceived(_ measurementsReadIndex: Int)
    @objc optional func measurementsReadIndexWritten(_ success: Bool)
    
}

class SensorService : NSObject, CBPeripheralDelegate, BluetoothService {
    
    // MARK: BluetoothService
    
    var uuid: CBUUID = CBUUID(string: "f000aa00-0451-4000-b000-000000000000")
    
    // MARK: Properties
    
    fileprivate var delegate: SensorServiceDelegate?
    fileprivate var sensor: CBPeripheral
    
    /**********  Services **********/
    
    fileprivate var sensorService: CBService?
    
    /**********  Characteristics **********/
    
    fileprivate var contractIDCharacteristic: CBCharacteristic?
    fileprivate var startTimeCharacteristic: CBCharacteristic?
    fileprivate var measurementsCharacteristic: CBCharacteristic?
    fileprivate var measurementsCountCharacteristic: CBCharacteristic?
    fileprivate var measurementsReadIndexCharacteristic: CBCharacteristic?
    fileprivate var recordingTimeIntervalCharacteristic: CBCharacteristic?
    fileprivate var isRecordingCharacteristic: CBCharacteristic?
    
    // MARK: Constants
    
    /********** Characteristics UUIDs **********/
    
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
    
    
    init(WithSensor sensor: CBPeripheral, WithDelegate delegate: SensorServiceDelegate?) {
        self.sensor = sensor
        self.delegate = delegate
        
        super.init()
        
        sensor.delegate = self
    }
    
    // MARK: Public methods
    
    /* 
     Method that is called to initialize the sensor service.
     Upon successful initialization, delegate method sensorServiceIsReady() called
     */
    func start() {
        sensor.discoverServices([uuid])
    }
    
    /*
     Checks if the sensor isn't recording
     To check the progress of sensor check, following delegate methods are useful:
     - isRecordingFlagReceived(_ isRecording: Bool)
     Note: can be called only by delegate only after sensorServiceIsReady() returned
     */
    func performSensorCheckBeforeSending() {
        /* check if necessary charactertistics are discovered */
        if let isRecordingCharacteristic = isRecordingCharacteristic {
            sensor.readValue(for: isRecordingCharacteristic)
        }
    }
    
    /*
     Initializes sending process for a parcel with given parameters
     To check the progress of initialiazing sensor for sending, following delegate methods are useful:
        - recordingTimeIntervalWritten(_ success: Bool)
        - contractIDWritten(_ success: Bool)
        - startTimeWritten(_ success: Bool)
        - isRecordingFlagWritten(_ success: Bool)
     Note: can be called only by delegate only after sensorIsReady() returned
     */
    func initializeParcelSending(WithContractID contractID: String, WithRecordingTimeInterval timeInterval: UInt8, WithStartTime startTime: Date) {
        /* check if necessary charactertistics are discovered */
        if let isRecordingCharacteristic = isRecordingCharacteristic, startTimeCharacteristic != nil && contractIDCharacteristic != nil && recordingTimeIntervalCharacteristic != nil {
            writeRecordingTimeInterval(timeInterval)
            writeContractId(contractID)
            writeStartTime(startTime)
            writeIsRecording(true)
            sensor.readValue(for: isRecordingCharacteristic)
        }
    }
    
    // MARK: CBPeripheralDelegate
    
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
            services.forEach({
                service in
                
                if service.uuid == uuid {
                    sensorService = service
                }
            })
            
            if let sensorService = sensorService {
                sensor.discoverCharacteristics([measurementsUUID, measurementsCountUUID, measurementsReadIndexUUID, isRecordingUUID, startTimeUUID, recordingTimeIntervalUUID, contractIDUUID], for: sensorService)
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
        if let sensorService = sensorService {
            guard service == sensorService else {
                log("Discovered characteristics for wrong service \(service.description)")
                return
            }
        } else {
            return
        }
        
        if let characteristics = service.characteristics {
            characteristics.forEach({
                characteristic in
                
                switch characteristic.uuid {
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
        
        if let delegate = delegate, allCharacteriticsDiscovered() {
            delegate.sensorServiceIsReady()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral == sensor else {
            log("Received write indication for wrong peripheral \(peripheral.name)")
            return
        }
        if let sensorService = sensorService {
            guard characteristic.service == sensorService else {
                log("Received write indication for wrong service \(characteristic.service.description)")
                return
            }
        } else {
            return
        }
        
        switch characteristic.uuid {
            case contractIDUUID:
                if let delegate = delegate {
                    delegate.contractIDWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write contract ID: \(error.localizedDescription)")
                }
            case isRecordingUUID:
                if let delegate = delegate {
                    delegate.isRecordingFlagWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write isRecording flag: \(error.localizedDescription)")
                }
            case startTimeUUID:
                if let delegate = delegate {
                    delegate.startTimeWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write startTime: \(error.localizedDescription)")
                }
            case recordingTimeIntervalUUID:
                if let delegate = delegate {
                    delegate.recordingTimeIntervalWritten?(error == nil)
                }
                if let error = error {
                    log("Failed to write timeInterval: \(error.localizedDescription)")
                }
            case measurementsReadIndexUUID:
                if let delegate = delegate {
                    delegate.measurementsReadIndexWritten?(error == nil)
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
        if let sensorService = sensorService {
            guard characteristic.service == sensorService else {
                log("Updated characteristic value for wrong service: \(characteristic.service.description)")
                return
            }
        } else {
            return
        }
        
        switch characteristic.uuid {
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
                        delegate.contractIDReceived?(contractID)
                    }
                }
            case isRecordingUUID:
                if let delegate = delegate, let isRecordingValue = characteristic.value, !isRecordingValue.isEmpty {
                    let isRecording: UInt8 = isRecordingValue[0]
                    if isRecording == 0xFF {
                        delegate.sensorServiceIsBroken()
                    } else {
                        if isRecording == 0x01 {
                            delegate.isRecordingFlagReceived?(true)
                        } else if isRecording == 0x00 {
                            delegate.isRecordingFlagReceived?(false)
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
        return contractIDCharacteristic            != nil &&
               startTimeCharacteristic             != nil &&
               measurementsCharacteristic          != nil &&
               measurementsCountCharacteristic     != nil &&
               measurementsReadIndexCharacteristic != nil &&
               recordingTimeIntervalCharacteristic != nil &&
               isRecordingCharacteristic           != nil
    }
    
}
