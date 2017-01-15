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
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool)
    
    /* Service discovery */
    func bluetoothManagerServicesDiscovered(_ peripheral: CBPeripheral, _ services: [CBService]?)
    
}

final class BluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /* Bluetooth Manager is a singleton */
    static let shared = BluetoothManager()
    
    // MARK: Properties
    
    var delegate: BluetoothManagerDelegate?

    fileprivate let centralManager: CBCentralManager
    fileprivate var peripheral: CBPeripheral?
    fileprivate var connectedServices: [BluetoothService] = []
    
    private override init() {
        centralManager = CBCentralManager.init(delegate: nil, queue: DispatchQueue.global(qos: .userInteractive))
        
        super.init()
        
        centralManager.delegate = self
    }
    
    // MARK: Public Methods
    
    func start() {
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func connect(Peripheral peripheral: CBPeripheral) {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        self.peripheral = peripheral
        self.peripheral!.delegate = self
        centralManager.connect(self.peripheral!, options: nil)
    }
    
    func disconnect(Peripheral peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /* Allows to scan given peripheral for list */
    func discoverServices(ForPeripheral peripheral: CBPeripheral, _ services: [CBUUID]) {
        self.peripheral = peripheral
        peripheral.delegate = self
        
        if let existingServices = peripheral.services {
            let existingServicesUUIDs: Set = Set(existingServices.map{ $0.uuid })
            let servicesUUIDs: Set = Set(services)
            if let delegate = delegate, servicesUUIDs.isSubset(of: existingServicesUUIDs) {
                delegate.bluetoothManagerServicesDiscovered(peripheral, existingServices)
            }
        } else {
            peripheral.discoverServices(services)
        }
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("\(peripheral.name) connected")
        
        if let delegate = delegate {
            delegate.bluetoothManagerPeripheralConnected(peripheral, true)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Failed to connect with \(peripheral.name): \(error?.localizedDescription)")
        if let bluetoothManagerDelegate = delegate {
            bluetoothManagerDelegate.bluetoothManagerPeripheralConnected(peripheral, false)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name {
            log("Discovered \(peripheralName)")
        }
        if let delegate = delegate {
            delegate.bluetoothManagerDiscoveredPeripheral(peripheral)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                if let delegate = delegate {
                    delegate.bluetoothManagerBluetoothPoweredOff()
                }
            case .unsupported, .unauthorized, .unknown:
                if let delegate = delegate {
                    delegate.bluetoothManagerBluetoothUnavailable()
                }
            case .poweredOn:
                if let delegate = delegate {
                    delegate.bluetoothManagerIsReady()
                }
            default:
                log("Unexpected state \(central.state)")
        }
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            log("Error discovering services for \(peripheral.name ?? peripheral.identifier.uuidString): \(error?.localizedDescription)")
            if let delegate = delegate {
                delegate.bluetoothManagerServicesDiscovered(peripheral, nil)
            }
            return
        }
        
        if let services = peripheral.services, let delegate = delegate {
            delegate.bluetoothManagerServicesDiscovered(peripheral, services)
        }
    }
    
}
