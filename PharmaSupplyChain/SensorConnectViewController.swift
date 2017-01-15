//
//  SensorConnectViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.12.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreBluetooth

class SensorConnectViewController : UIViewController, BluetoothManagerDelegate, SensorServiceDelegate, BatteryLevelServiceDelegate {
    
    // MARK: Properties
    
    var deviceMacAddress: String? = "SensorTag 2.0"
    
    fileprivate var batteryLevelService: BatteryLevelService?
    fileprivate var sensorService: SensorService?
    
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
        bluetoothManager.start()
    }
    
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        // TODO: add timeout so that scanning doesn't last forever
        if let deviceMacAddress = deviceMacAddress, let peripheralName = peripheral.name, peripheralName == deviceMacAddress {
            bluetoothManager.connect(Peripheral: peripheral)
        } else {
            // TODO: handle no valid mac address is passed
        }
    }
    
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool) {
        guard let peripheralName = peripheral.name, let deviceMacAddress = deviceMacAddress, peripheralName == deviceMacAddress else {
            log("Wrong peripheral connected: \(peripheral.name)")
            bluetoothManager.disconnect(Peripheral: peripheral)
            return
        }
        bluetoothManager.discoverServices(ForPeripheral: peripheral, [SensorService.uuid, BatteryLevelService.uuid])
    }
    
    func bluetoothManagerServicesDiscovered(_ peripheral: CBPeripheral, _ services: [CBService]?) {
        guard let peripheralName = peripheral.name, let deviceMacAddress = deviceMacAddress, peripheralName == deviceMacAddress else {
            log("Discovered services for wrong peripheral \(peripheral.name)")
            bluetoothManager.disconnect(Peripheral: peripheral)
            return
        }
        
        if let services = services {
            for service in services {
                switch service.uuid {
                    case BatteryLevelService.uuid:
                        batteryLevelService = BatteryLevelService(WithSensor: peripheral, WithService: service, WithDelegate: self)
                        batteryLevelService!.start()
                    case SensorService.uuid:
                        sensorService = SensorService(WithSensor: peripheral, WithService: service, WithDelegate: self)
                        sensorService!.start()
                    default:
                        break
                }
            }
        } else {
            /* TODO: add error view saying that user should try to use another sensor */
        }
    }
    
    // MARK: SensorServiceDelegate
    
    func sensorServiceIsReady() {
        if let sensorService = sensorService {
            sensorService.performSensorCheckBeforeSending()
        }
    }
    
    func sensorServiceIsBroken() {
        let sensorBrokenAlertController = UIAlertController(title: nil, message: "The sensor is broken! Please, try to use another sensor!", preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: {
            _ in
            
            sensorBrokenAlertController.dismiss(animated: true, completion: nil)
        })
        
        sensorBrokenAlertController.addAction(dismissAction)
        
        present(sensorBrokenAlertController, animated: true, completion: nil)
    }
    
    func isRecordingFlagReceived(_ isRecording: Bool) {
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
    
    // MARK: BatteryLevelServiceDelegate
    
    func batteryLevelServiceIsReady() {
        if let batteryLevelService = batteryLevelService {
            batteryLevelService.requestBatteryLevel()
        }
    }
    
    func batteryLevelReceived(_ batteryLevel: Int) {
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
    
}
