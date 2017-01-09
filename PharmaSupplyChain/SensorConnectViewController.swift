//
//  SensorConnectViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.12.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreBluetooth

class SensorConnectViewController : UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: Properties
    
    fileprivate var centralManager: CBCentralManager!
    fileprivate var sensor: CBPeripheral?
    
    // MARK: Constants
    
    /* main sensor service UUID */
    fileprivate let sensorServiceUUID: CBUUID =  CBUUID(string: "F000AA00-0451-4000-B000-000000000000")
    /* sensor battery level characterstic UUID */
    fileprivate let batteryLevelCharactersticUUID: CBUUID = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("\(peripheral.name) connected")
        log("Discovering services...")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name {
            log("Discovered \(peripheralName)")
            if isValidMacAddress(peripheralName) || peripheralName == "SensorTag 2.0" || peripheralName == "CC2650 SensorTag" {
                centralManager.stopScan()
                sensor = peripheral
                sensor!.delegate = self
                centralManager.connect(sensor!, options: nil)
            }
            log("\(advertisementData)")
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                log("Bluetooth is powered off")
            case .poweredOn:
                log("Bluetooth is powered on")
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            case .unsupported:
                log("Bluetooth is unsupported")
            case .unauthorized:
                log("Unauthorized usage of Bluetooth")
            default:
                log("Unexpected state \(central.state)")
        }
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            log("Error discovering service: \(error.localizedDescription)")
        }
        log("Discovered new services from \(peripheral.name)")
        if let services = peripheral.services {
            for service in services {
                log("Service: \(service.description)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log("Characteristics for service \(service.description): \(service.characteristics)")
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                log("Characteristic: \(characteristic.description)")
                if characteristic.uuid == batteryLevelCharactersticUUID {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, characteristic.uuid == batteryLevelCharactersticUUID {
            log("Sensor battery level is \(value[0])")
        }
    }
    
}
