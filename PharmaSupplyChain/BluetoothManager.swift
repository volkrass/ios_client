//
//  BluetoothManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 10.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol BluetoothManagerDelegate {
    
    /* BluetoothManager states */
    func bluetoothManagerBluetoothPoweredOff()
    func bluetoothManagerBluetoothUnavailable()
    func bluetoothManagerIsReady()
    
    /* Peripheral discovery */
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral)
    
    /* Peripheral connection */
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool, _ connectedServices: [BluetoothService]?)
    
}

final class BluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /* Bluetooth Manager is a singleton */
    static let shared = BluetoothManager()
    
    // MARK: Properties
    
    var bluetoothManagerDelegate: BluetoothManagerDelegate?
    var sensorServiceDelegate: SensorServiceDelegate?
    var batteryLevelServiceDelegate: BatteryLevelServiceDelegate?

    fileprivate let centralManager: CBCentralManager
    fileprivate var connectedServices: [BluetoothService] = []
    
    private override init() {
        centralManager = CBCentralManager.init(delegate: nil, queue: DispatchQueue.global(qos: .userInteractive))
        
        super.init()
        
        centralManager.delegate = self
    }
    
    // MARK: Public Methods
    
    func startScanning() {
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func connect(Peripheral peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(Peripheral peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("\(peripheral.name) connected")
        
        let sensorService = SensorService(WithSensor: peripheral, WithDelegate: sensorServiceDelegate)
        let batteryLevelService = BatteryLevelService(WithSensor: peripheral, WithDelegate: batteryLevelServiceDelegate)
        if !connectedServices.contains(where: {
            service in
            
            return service.uuid == sensorService.uuid
        }) {
            connectedServices.append(sensorService)
            sensorService.start()
        }
        if !connectedServices.contains(where: {
            service in
            
            return service.uuid == batteryLevelService.uuid
        }) {
            connectedServices.append(batteryLevelService)
            batteryLevelService.start()
        }
        
        if let bluetoothManagerDelegate = bluetoothManagerDelegate {
            bluetoothManagerDelegate.bluetoothManagerPeripheralConnected(peripheral, true, connectedServices)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Failed to connect with \(peripheral.name): \(error?.localizedDescription)")
        if let bluetoothManagerDelegate = bluetoothManagerDelegate {
            bluetoothManagerDelegate.bluetoothManagerPeripheralConnected(peripheral, false, nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name {
            log("Discovered \(peripheralName)")
        }
        if let bluetoothManagerDelegate = bluetoothManagerDelegate {
            bluetoothManagerDelegate.bluetoothManagerDiscoveredPeripheral(peripheral)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                if let bluetoothManagerDelegate = bluetoothManagerDelegate {
                    bluetoothManagerDelegate.bluetoothManagerBluetoothPoweredOff()
                }
            case .unsupported, .unauthorized, .unknown:
                if let bluetoothManagerDelegate = bluetoothManagerDelegate {
                    bluetoothManagerDelegate.bluetoothManagerBluetoothUnavailable()
                }
            case .poweredOn:
                if let bluetoothManagerDelegate = bluetoothManagerDelegate {
                    bluetoothManagerDelegate.bluetoothManagerIsReady()
                }
            default:
                log("Unexpected state \(central.state)")
        }
    }
    
}
