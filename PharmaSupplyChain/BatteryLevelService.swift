//
//  BatteryLevelService.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

@objc protocol BatteryLevelServiceDelegate {
    
    func batteryLevelServiceIsReady()
    
    @objc optional func batteryLevelReceived(_ batteryLevel: Int)
    
}

class BatteryLevelService : NSObject, CBPeripheralDelegate, BluetoothService {
    
    // MARK: BluetoothService
    
    static var uuid: CBUUID = CBUUID(string: "0000180f-0000-1000-8000-00805f9b34fb")
    
    // MARK: Properties
    
    fileprivate var delegate: BatteryLevelServiceDelegate?
    fileprivate var sensor: CBPeripheral
    
    fileprivate var batteryLevelService: CBService
    
    fileprivate var batteryLevelCharacteristic: CBCharacteristic?
    
    // MARK: Constants
    
    /* sensor battery level characterstic UUID, in % */
    fileprivate let batteryLevelUUID: CBUUID = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb")
    
    
    init(WithSensor sensor: CBPeripheral, WithService service: CBService, WithDelegate delegate: BatteryLevelServiceDelegate?) {
        self.sensor = sensor
        self.batteryLevelService = service
        self.delegate = delegate
        
        super.init()
        
        sensor.delegate = self
    }
    
    // MARK: Public methods
    
    /*
     Method that is called to initialize battery level service.
     Upon successful initialization, delegate method sensorIsReady() called
     */
    func start() {
        sensor.discoverCharacteristics([batteryLevelUUID], for: batteryLevelService)
    }
    
    /*
     Checks sensor battery level, in %
     Result returned as in delegate method:
     - batteryLevelReceived(_ batteryLevel: Int)
     Note: can be called only by delegate only after baterryLevelServiceIsReady() returned
    */
    func requestBatteryLevel() {
        if let batteryLevelCharacteristic = batteryLevelCharacteristic {
            sensor.readValue(for: batteryLevelCharacteristic)
        }
    }
    
    // MARK: CBPeripheralDelegate
    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard error == nil else {
//            log("Error discovering services: \(error!.localizedDescription)")
//            return
//        }
//        guard peripheral == sensor else {
//            log("Discovered services for wrong peripheral \(peripheral.name)")
//            return
//        }
//        
//        if let services = peripheral.services, !services.isEmpty {
//            services.forEach({
//                service in
//                
//                if service.uuid == uuid {
//                    batteryLevelService = service
//                }
//            })
//            
//            if let batteryLevelService = batteryLevelService {
//                sensor.discoverCharacteristics([batteryLevelUUID], for: batteryLevelService)
//            }
//        }
//    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            log("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        guard peripheral == sensor else {
            log("Discovered service characteristics for wrong peripheral \(peripheral.name)")
            return
        }
        guard service == batteryLevelService else {
            log("Discovered characteristics for wrong service \(service.description)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == batteryLevelUUID {
                    batteryLevelCharacteristic = characteristic
                }
            }
        }
        
        if let delegate = delegate, batteryLevelCharacteristic != nil {
            delegate.batteryLevelServiceIsReady()
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
        
        guard characteristic.service == batteryLevelService else {
            log("Discovered characteristics for wrong service \(characteristic.service.description)")
            return
        }
        
        if characteristic.uuid == batteryLevelUUID {
            if let delegate = delegate, let batteryLevelValue = characteristic.value, !batteryLevelValue.isEmpty {
                delegate.batteryLevelReceived?(Int(batteryLevelValue[0]))
            }
        }
    }
    
}
