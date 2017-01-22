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
    
    var sensorMACAddress: String? = "SensorTag 2.0"
    var contractID: String?
    
    fileprivate var modumSensor: ModumSensor?
    fileprivate let bluetoothManager: BluetoothManager = BluetoothManager.shared
    
    // MARK: Constants
    
    /* sensor should have at least 30% of battery before sending process */
    fileprivate let MIN_BATTERY_LEVEL: Int = 30
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var progressBar: UIProgressView!
    @IBOutlet weak fileprivate var progressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let contractID = contractID else {
            log("contractID string is nil!")
            /* TODO: display internal error and dismiss all screens */
            return
        }
        guard let sensorMACAddress = sensorMACAddress else {
            log("Sensor MAC address string is nil!")
            /* TODO: display internal error and dismiss all screens */
            return
        }
        
        bluetoothManager.delegate = self
        
        navigationController?.navigationBar.isHidden = true
        
        progressLabel.textColor = MODUM_DARK_BLUE
        progressLabel.text = "Searching for sensor..."
        
        progressBar.progressTintColor = MODUM_LIGHT_BLUE
        
        if let progressView = progressBar.superview {
            progressView.layer.cornerRadius = 3.0
        }
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
        progressLabel.text = "Discovering sensor devices..."
        bluetoothManager.scanForPeripheral(WithName: sensorMACAddress, WithTimeout: 15.0)
    }
    
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        if let peripheralName = peripheral.name, peripheralName == sensorMACAddress! {
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
        guard let peripheralName = peripheral.name, peripheralName == sensorMACAddress! else {
            log("Wrong peripheral connected: \(peripheral.name)")
            bluetoothManager.disconnect(Peripheral: peripheral)
            return
        }
        modumSensor = ModumSensor(WithPeripheral: peripheral)
        modumSensor!.delegate = self
        modumSensor!.start()
        
        progressBar.progress = 0.25
        progressLabel.text = "Connected to the sensor"
        let dispatchAfter = DispatchTime.now() + 1.0
        DispatchQueue.main.asyncAfter(deadline: dispatchAfter, execute: {
            [weak self] in
            
            if let sensorConnectViewController = self {
                sensorConnectViewController.progressLabel.text = "Validating sensor characteristics..."
            }
        })
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
        progressLabel.text = "Sensor is ready to use..."
        progressBar.progress = 0.5
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
