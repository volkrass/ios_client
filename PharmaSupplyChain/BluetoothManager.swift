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
    static let shared: BluetoothManager = BluetoothManager()
    
    // MARK: Properties
    
    var delegate: BluetoothManagerDelegate?

    fileprivate let centralManager: CBCentralManager
    fileprivate var peripheral: CBPeripheral?
    fileprivate let dispatchQueue: DispatchQueue
    
    /* helper variables */
    fileprivate var numTriesToGetState: Int = 0
    fileprivate var scanTimer: Timer?
    
    fileprivate var nameToScanFor: String?
    
    private override init() {
        dispatchQueue = DispatchQueue.global(qos: .userInteractive)
        centralManager = CBCentralManager.init(delegate: nil, queue: dispatchQueue)
        
        super.init()
        
        centralManager.delegate = self
    }
    
    // MARK: Public Methods
    
    func start() {
        numTriesToGetState = 0
        let dispatchAfter = DispatchTime.now() + 0.5
        dispatchQueue.asyncAfter(deadline: dispatchAfter, execute: {
            [weak self] in
            
            if let bluetoothManager = self {
                let state = bluetoothManager.getBluetoothState()
                if state == .unknown {
                    if bluetoothManager.numTriesToGetState >= 3 {
                        if let delegate = bluetoothManager.delegate {
                            delegate.bluetoothManagerBluetoothUnavailable()
                        }
                    } else {
                        bluetoothManager.dispatchQueue.asyncAfter(deadline: dispatchAfter + 1.0, execute: {
                            [weak self] in
                            
                            if let bluetoothManager = self {
                                bluetoothManager.start()
                            }
                        })
                    }
                }
            }
        })
    }
    
    func scanForPeripheral(WithName name: String?, WithTimeout timeout: Double?) {
        if !centralManager.isScanning {
            nameToScanFor = name
            if let timeout = timeout {
                DispatchQueue.main.async {
                    [weak self] in
                    
                    if let bluetoothManager = self {
                        bluetoothManager.scanTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: {
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
                    }
                }
            }
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func connect(peripheral: CBPeripheral) {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        self.peripheral = peripheral
        centralManager.connect(self.peripheral!, options: nil)
    }
    
    func disconnect(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        self.peripheral = nil
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("\(peripheral.name) connected")
        
        if let scanTimer = scanTimer {
            scanTimer.invalidate()
            self.scanTimer = nil
        }
        
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
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            log("Failed to disconnect peripheral \(peripheral.name): \((error as NSError).userInfo)")
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        /* TODO: react on change to Bluetooth state */
    }

    // MARK: Helper methods
    
    fileprivate func getBluetoothState() -> CBManagerState {
        switch centralManager.state {
        case .poweredOff:
            if let delegate = delegate {
                delegate.bluetoothManagerBluetoothPoweredOff()
            }
        case .unsupported, .unauthorized:
            if let delegate = delegate {
                delegate.bluetoothManagerBluetoothUnavailable()
            }
        case .poweredOn:
            if let delegate = delegate {
                delegate.bluetoothManagerIsReady()
            }
        case .unknown:
            break
        default:
            log("Unexpected state \(centralManager.state)")
        }
        
        return centralManager.state
    }
    
}
