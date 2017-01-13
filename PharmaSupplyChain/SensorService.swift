//
//  SensorService.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 11.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol SensorServiceDelegate {
    
    func sensorIsReady()
    func sensorIsBroken()
    
    func batteryLevelReceived(_ batteryLevel: Int)
    
    func contractIDReceived(_ contractID: String)
    func contractIDWritten(_ success: Bool)
    
    func isRecordingFlagReceived(_ isRecording: Bool)
    func isRecordingFlagWritten(_ success: Bool)
    
    func recordingTimeIntervalReceived(_ recordingTimeInterval: Date)
    func recordingTimeIntervalWritten(_ success: Bool)
    
    func startTimeReceived(_ startTime: Date)
    func startTimeWritten(_ success: Bool)
    
    func measurementsCountReceived(_ measurementsCount: Int)
    
    func measurementsReadIndexReceived(_ measurementsReadIndex: Int)
    func measurementsReadIndexWritten(_ success: Bool)
    
}

class SensorService : NSObject, CBPeripheralDelegate {
    
    // MARK: Properties
    
    fileprivate var delegate: SensorServiceDelegate?
    fileprivate var sensor: CBPeripheral
    
    /**********  Services **********/
    
    fileprivate var batteryLevelService: CBService?
    fileprivate var sensorService: CBService?
    
    /**********  Characteristics **********/
    
    fileprivate var contractIDCharacteristic: CBCharacteristic?
    fileprivate var startTimeCharacteristic: CBCharacteristic?
    fileprivate var batteryLevelCharacteristic: CBCharacteristic?
    fileprivate var measurementsCharacteristic: CBCharacteristic?
    fileprivate var measurementsCountCharacteristic: CBCharacteristic?
    fileprivate var measurementsReadIndexCharacteristic: CBCharacteristic?
    fileprivate var recordingTimeIntervalCharacteristic: CBCharacteristic?
    fileprivate var isRecordingCharacteristic: CBCharacteristic?
    
    // MARK: Constants
    
    /**********  Service UUIDs **********/
    
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
    
    /* minimum battery level of the sensor, in %, that is sufficient for initiating send process */
    fileprivate let MIN_BATTERY_LEVEL: Int = 30
    
    
    init(WithSensor sensor: CBPeripheral, WithDelegate delegate: SensorServiceDelegate?) {
        self.sensor = sensor
        self.delegate = delegate
        
        super.init()
        
        sensor.delegate = self
    }
    
    // MARK: Public methods
    
    /* 
     Method that is called to initialize the sensor service.
     Upon successful initialization, delegate method sensorIsReady() called
     */
    func start() {
        sensor.discoverServices([sensorServiceUUID, batteryLevelServiceUUID])
    }
    
    /*
     Checks if sensor battery level is sufficient and that the sensor isn't recording
     To check the progress of sensor check, following delegate methods are useful:
     - batteryLevelReceived(_ batteryLevel: Int)
     - isRecordingFlagReceived(_ isRecording: Bool)
     Note: can be called only by delegate only after sensorIsReady() returned
     */
    func performSensorCheckBeforeSending() {
        /* check if necessary charactertistics are discovered */
        if let batteryLevelCharacteristic = batteryLevelCharacteristic, let isRecordingCharacteristic = isRecordingCharacteristic {
            sensor.readValue(for: batteryLevelCharacteristic)
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
                
                if service.uuid == batteryLevelServiceUUID {
                    batteryLevelService = service
                } else if service.uuid == sensorServiceUUID {
                    sensorService = service
                }
            })
            
            if let batteryLevelService = batteryLevelService {
                sensor.discoverCharacteristics([batteryLevelUUID], for: batteryLevelService)
            }
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
        if let batteryLevelService = batteryLevelService, let sensorService = sensorService {
            guard service == batteryLevelService || service == sensorService else {
                log("Discovered characteristics for wrong service \(service.description)")
                return
            }
        } else if let batteryLevelService = batteryLevelService {
            guard service == batteryLevelService else {
                log("Discovered characteristics for wrong service \(service.description)")
                return
            }
        } else if let sensorService = sensorService {
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
        
        if let delegate = delegate, allCharacteriticsDiscovered() {
            delegate.sensorIsReady()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral == sensor else {
            log("Received write indication for wrong peripheral \(peripheral.name)")
            return
        }
        let service = characteristic.service
        if let batteryLevelService = batteryLevelService, let sensorService = sensorService {
            guard service == batteryLevelService || service == sensorService else {
                log("Received write indication for wrong service \(service.description)")
                return
            }
        } else if let batteryLevelService = batteryLevelService {
            guard service == batteryLevelService else {
                log("Received write indication for wrong service \(service.description)")
                return
            }
        } else if let sensorService = sensorService {
            guard service == sensorService else {
                log("Received write indication for wrong service \(service.description)")
                return
            }
        } else {
            return
        }
        
        switch characteristic.uuid {
            case contractIDUUID:
                if let delegate = delegate {
                    delegate.contractIDWritten(error == nil)
                }
                if let error = error {
                    log("Failed to write contract ID: \(error.localizedDescription)")
                }
            case isRecordingUUID:
                if let delegate = delegate {
                    delegate.isRecordingFlagWritten(error == nil)
                }
                if let error = error {
                    log("Failed to write isRecording flag: \(error.localizedDescription)")
                }
            case startTimeUUID:
                if let delegate = delegate {
                    delegate.startTimeWritten(error == nil)
                }
                if let error = error {
                    log("Failed to write startTime: \(error.localizedDescription)")
                }
            case recordingTimeIntervalUUID:
                if let delegate = delegate {
                    delegate.recordingTimeIntervalWritten(error == nil)
                }
                if let error = error {
                    log("Failed to write timeInterval: \(error.localizedDescription)")
                }
            case measurementsReadIndexUUID:
                if let delegate = delegate {
                    delegate.measurementsReadIndexWritten(error == nil)
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
        let service = characteristic.service
        if let batteryLevelService = batteryLevelService, let sensorService = sensorService {
            guard service == batteryLevelService || service == sensorService else {
                log("Updated characteristic value for wrong service: \(service.description)")
                return
            }
        } else if let batteryLevelService = batteryLevelService {
            guard service == batteryLevelService else {
                log("Updated characteristic value for wrong service: \(service.description)")
                return
            }
        } else if let sensorService = sensorService {
            guard service == sensorService else {
                log("Updated characteristic value for wrong service: \(service.description)")
                return
            }
        } else {
            return
        }
        
        switch characteristic.uuid {
            case batteryLevelUUID:
                if let delegate = delegate, let batteryLevelValue = characteristic.value, !batteryLevelValue.isEmpty {
                    delegate.batteryLevelReceived(Int(batteryLevelValue[0]))
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
                        delegate.contractIDReceived(contractID)
                    }
                }
            case isRecordingUUID:
                if let delegate = delegate, let isRecordingValue = characteristic.value, !isRecordingValue.isEmpty {
                    let isRecording: UInt8 = isRecordingValue[0]
                    if isRecording == 0xFF {
                        delegate.sensorIsBroken()
                    } else {
                        if isRecording == 0x01 {
                            delegate.isRecordingFlagReceived(true)
                        } else if isRecording == 0x00 {
                            delegate.isRecordingFlagReceived(false)
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
               batteryLevelCharacteristic          != nil &&
               measurementsCharacteristic          != nil &&
               measurementsCountCharacteristic     != nil &&
               measurementsReadIndexCharacteristic != nil &&
               recordingTimeIntervalCharacteristic != nil &&
               isRecordingCharacteristic           != nil
    }
    
}
