//
//  SensorService.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 11.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol SensorServiceDelegate {
    
    func batteryLevelUpdated(_ batteryLevel: Int)
    
    func contractIDUpdated(_ contractID: Int)
    
    func isRecordingFlagUpdated(_ isRecording: Bool)
    
    func recordingTimeIntervalUpdated(_ recordingTimeInterval: Date)
    
    func measurementsCountUpdated(_ measurementsCount: Int)
    
    func measurementsReadIndexUpdated(_ measurementsReadIndex: Int)
    
    func startTimeUpdated(_ startTime: Date)
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
    
    
    init(WithSensor sensor: CBPeripheral, WithDelegate delegate: SensorServiceDelegate?) {
        self.sensor = sensor
        self.delegate = delegate
        
        super.init()
        
        sensor.delegate = self
    }
    
    func start() {
        sensor.discoverServices([sensorServiceUUID, batteryLevelServiceUUID])
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
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
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
                if let delegate = delegate, let batteryLevelValue = characteristic.value {
                    delegate.batteryLevelUpdated(Int(batteryLevelValue[0]))
                }
            case contractIDUUID:
                if let delegate = delegate, let contractIDValue = characteristic.value {
                    /* TODO: extract contract ID */
                    //delegate.contractIDUpdated()
                }
            default:
                break
        }
    }
    
    // MARK: Characteristics Interaction
    
}
