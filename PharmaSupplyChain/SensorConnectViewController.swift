//
//  SensorConnectViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.12.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreBluetooth

class SensorConnectViewController : UIViewController, BluetoothManagerDelegate, ModumSensorDelegate {
    
    // MARK: Properties
    
    var deviceMacAddress: String? = "SensorTag 2.0"
    
    fileprivate var modumSensor: ModumSensor?
    fileprivate let bluetoothManager: BluetoothManager = BluetoothManager.shared
    
    // MARK: Constants
    
    /* sensor should have at least 30% of battery before sending process */
    fileprivate let MIN_BATTERY_LEVEL: Int = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.delegate = self
    }
    
    // MARK: BluetoothDiscoveryDelegate
    
    func bluetoothManagerBluetoothPoweredOff() {
        let noBluetoothAlertController = UIAlertController(title: nil, message: "Bluetooth is turned off. Please, turn on Bluetooth in Settings.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            _ in
            
            noBluetoothAlertController.dismiss(animated: true, completion: nil)
        })
        let goToSettingsAction = UIAlertAction(title: "Settings", style: .default, handler: {
            _ in
            
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(settingsURL, completionHandler: nil)
            }
        })
        noBluetoothAlertController.addAction(goToSettingsAction)
        noBluetoothAlertController.addAction(cancelAction)
        
        present(noBluetoothAlertController, animated: true, completion: nil)
    }
    
    func bluetoothManagerBluetoothUnavailable() {
        let bluetoothUnavailableAlertController = UIAlertController(title: nil, message: "Bluetooth is unavaible on your device. Please, contact your administrator or Apple support", preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
            _ in
            
            bluetoothUnavailableAlertController.dismiss(animated: true, completion: nil)
        })
        
        bluetoothUnavailableAlertController.addAction(dismissAction)
        
        present(bluetoothUnavailableAlertController, animated: true, completion: nil)
    }
    
    func bluetoothManagerIsReady() {
        bluetoothManager.scanForPeripheral(WithName: deviceMacAddress, WithTimeout: 15.0)
    }
    
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        if let deviceMacAddress = deviceMacAddress, let peripheralName = peripheral.name, peripheralName == deviceMacAddress {
            bluetoothManager.connect(Peripheral: peripheral)
        }
    }
    
    func bluetoothManagerFailedToDiscoverPeripheral() {
        let discoveryFailureAlertController = UIAlertController(title: nil, message: "Modum sensor device isn't in range! Please, check battery level of the sensor and make sure that sensor is operating!", preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
            _ in
            
            discoveryFailureAlertController.dismiss(animated: true, completion: nil)
        })
        
        discoveryFailureAlertController.addAction(dismissAction)
        
        present(discoveryFailureAlertController, animated: true, completion: nil)
    }
    
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool) {
        guard let peripheralName = peripheral.name, let deviceMacAddress = deviceMacAddress, peripheralName == deviceMacAddress else {
            log("Wrong peripheral connected: \(peripheral.name)")
            bluetoothManager.disconnect(Peripheral: peripheral)
            return
        }
        modumSensor = ModumSensor(WithPeripheral: peripheral)
        modumSensor!.delegate = self
        modumSensor!.start()
    }
    
    // MARK: ModumSensorDelegate
    
    func modumSensorIsReady() {
        if let modumSensor = modumSensor {
            /* performing sensor check before sending */
            modumSensor.requestBatteryLevel()
            modumSensor.requestIsRecording()
        }
    }
    
    func modumSensorServiceUnsupported() {
        let sensorUnsupportedAlertController =  UIAlertController(title: nil, message: "Scanned device doesn't support required services! Please, try to connect to another device!", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
            _ in
            
            sensorUnsupportedAlertController.dismiss(animated: true, completion: nil)
        })
        
        sensorUnsupportedAlertController.addAction(dismissAction)
        
        present(sensorUnsupportedAlertController, animated: true, completion: nil)
    }
    
    func modumSensorIsBroken() {
        let sensorBrokenAlertController = UIAlertController(title: nil, message: "The sensor is broken! Please, try to use another sensor!", preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
            _ in
            
            sensorBrokenAlertController.dismiss(animated: true, completion: nil)
        })
        
        sensorBrokenAlertController.addAction(dismissAction)
        
        present(sensorBrokenAlertController, animated: true, completion: nil)
    }
    
    func modumSensorContractIDReceived(_ contractID: String) {
        log("Received contract ID \(contractID)")
    }
    
    func modumSensorBatteryLevelReceived(_ batteryLevel: Int) {
        if batteryLevel <= MIN_BATTERY_LEVEL {
            let outOfBatteryAlertController = UIAlertController(title: nil, message: "Sensor battery level is too low. Please, replace battery inside the sensor and try again!", preferredStyle: .alert)
            
            let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
                [weak self]
                _ in
                
                if let sensorConnectController = self {
                    outOfBatteryAlertController.dismiss(animated: true, completion: nil)
                    sensorConnectController.dismiss(animated: true, completion: nil)
                }
            })
            
            outOfBatteryAlertController.addAction(dismissAction)
            
            present(outOfBatteryAlertController, animated: true, completion: nil)
        }
    }
    
    func modumSensorIsRecordingFlagReceived(_ isRecording: Bool) {
        if isRecording {
            let sensorIsRecordingAlertController = UIAlertController(title: nil, message: "This sensor is in recording mode! Please, try to use another sensor!", preferredStyle: .alert)
            
            let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
                _ in
                
                sensorIsRecordingAlertController.dismiss(animated: true, completion: nil)
            })
            
            sensorIsRecordingAlertController.addAction(dismissAction)
            
            present(sensorIsRecordingAlertController, animated: true, completion: nil)
        }
    }
    
}
