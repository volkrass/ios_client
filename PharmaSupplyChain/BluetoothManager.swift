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
    func bluetoothManagerFailedToDiscoverPeripheral()
    
    /* Peripheral connection */
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool)
    
}

final class BluetoothManager : NSObject, CBCentralManagerDelegate {
    
    /* Bluetooth Manager is a singleton */
    static let shared = BluetoothManager()
    
    // MARK: Properties
    
    var delegate: BluetoothManagerDelegate?

    fileprivate let centralManager: CBCentralManager
    fileprivate var peripheral: CBPeripheral?
    
    fileprivate var scanTimer: Timer?
    fileprivate var nameToScanFor: String?
    
    private override init() {
        centralManager = CBCentralManager.init(delegate: nil, queue: DispatchQueue.global(qos: .userInteractive))
        
        super.init()
        
        centralManager.delegate = self
    }
    
    // MARK: Public Methods
    
    func scanForPeripheral(WithName name: String?, WithTimeout timeout: Double?) {
        if !centralManager.isScanning {
            nameToScanFor = name
            if let timeout = timeout {
                scanTimer = Timer(timeInterval: timeout, repeats: false, block: {
                    [weak self]
                    timer in
                    
                    log("Scan didn't find peripheral \(name) in \(timeout) seconds! Finishing scan...")
                    timer.invalidate()
                    
                    if let bluetoothManager = self {
                        bluetoothManager.centralManager.stopScan()
                        if let delegate = bluetoothManager.delegate {
                            delegate.bluetoothManagerFailedToDiscoverPeripheral()
                        }
                    }
                })
                RunLoop.current.add(scanTimer!, forMode: .defaultRunLoopMode)
            }
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func connect(Peripheral peripheral: CBPeripheral) {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        self.peripheral = peripheral
        centralManager.connect(self.peripheral!, options: nil)
    }
    
    func disconnect(Peripheral peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
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
            if let nameToScanFor = nameToScanFor, peripheralName == nameToScanFor {
                centralManager.stopScan()
                if let scanTimer = scanTimer {
                    scanTimer.invalidate()
                }
                if let delegate = delegate {
                    delegate.bluetoothManagerDiscoveredPeripheral(peripheral)
                }
            } else {
                if let delegate = delegate {
                    delegate.bluetoothManagerDiscoveredPeripheral(peripheral)
                }
            }
            log("Discovered \(peripheralName)")
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
    
}
