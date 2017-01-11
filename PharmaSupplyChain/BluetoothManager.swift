//
//  BluetoothManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 10.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol BluetoothDiscoveryDelegate {
    
    func sensorDiscovered()
    
    func bluetoothErrorOccurred()
    
}

final class BluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /* Bluetooth Manager is a singleton */
    static let shared = BluetoothManager()
    
    // MARK: Properties
    
    var bluetoothDiscoveryDelegate: BluetoothDiscoveryDelegate?
    var sensorServiceDelegate: SensorServiceDelegate?

    fileprivate let centralManager: CBCentralManager
    
    private override init() {
        centralManager = CBCentralManager.init(delegate: nil, queue: DispatchQueue.global(qos: .userInteractive))
        
        super.init()
        
        centralManager.delegate = self
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("\(peripheral.name) connected")
        
        let sensorService = SensorService(WithSensor: peripheral, WithDelegate: sensorServiceDelegate)
        sensorService.start()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name {
            log("Discovered \(peripheralName)")
            if isValidMacAddress(peripheralName) || peripheralName == "SensorTag 2.0" || peripheralName == "CC2650 SensorTag" {
                centralManager.stopScan()
    
                if let bluetoothDiscoveryDelegate = bluetoothDiscoveryDelegate {
                    bluetoothDiscoveryDelegate.sensorDiscovered()
                }
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff, .unsupported, .unauthorized, .unknown:
                if let bluetoothDiscoveryDelegate = bluetoothDiscoveryDelegate {
                    bluetoothDiscoveryDelegate.bluetoothErrorOccurred()
                }
            case .poweredOn:
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            default:
                log("Unexpected state \(central.state)")
        }
    }
    
}
