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
    
    var sensorMACAddress: String?
    var contractID: String?
    var isReceivingParcel: Bool = false
    
    fileprivate var modumSensor: ModumSensor?
    fileprivate var bluetoothManager: BluetoothManager?
    
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
            
            let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
            let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                [weak self]
                _ in
                
                if let sensorConnectViewController = self {
                    internalErrorAlertController.dismiss(animated: true, completion: nil)
                    _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            present(alertControllerWithDismiss, animated: true, completion: nil)
            
            return
        }
        if !isReceivingParcel {
            guard let sensorMACAddress = sensorMACAddress else {
                log("Sensor MAC address string is nil!")
                
                let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
                let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let sensorConnectViewController = self {
                        internalErrorAlertController.dismiss(animated: true, completion: nil)
                        _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
                
                return
            }
        }
        
        bluetoothManager = BluetoothManager.shared
        bluetoothManager!.delegate = self
        bluetoothManager!.start()
        
        navigationController?.navigationBar.isHidden = true
        
        progressLabel.textColor = MODUM_DARK_BLUE
        progressLabel.text = "Searching for sensor..."
        progressBar.setProgress(0.1, animated: false)
        
        progressBar.progressTintColor = MODUM_LIGHT_BLUE
        
        if let progressView = progressBar.superview {
            progressView.layer.cornerRadius = 3.0
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        bluetoothManager = nil
        modumSensor = nil
    }
    
    // MARK: BluetoothDiscoveryDelegate
    
    func bluetoothManagerBluetoothPoweredOff() {
        let noBluetoothAlertController = UIAlertController(title: nil, message: "Bluetooth is turned off. Please, turn on Bluetooth in Settings.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            [weak self]
            _ in
            
            if let sensorConnectViewController = self {
                noBluetoothAlertController.dismiss(animated: true, completion: nil)
                _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
            }
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
        let alertControllerWithDismiss = bluetoothUnavailableAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let sensorConnectViewController = self {
                bluetoothUnavailableAlertController.dismiss(animated: true, completion: nil)
                _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func bluetoothManagerIsReady() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(0.2, animated: true)
            }
        }
        
        UserDefaults.standard.set(["A0E6F8C1D386"], forKey: "bluetoothDevices")
        
        if isReceivingParcel {
            bluetoothManager!.scanForPeripheral(WithName: nil, WithTimeout: 15.0)
        } else {
            /* TODO: debug */
            if var devicesArray = UserDefaults.standard.array(forKey: "bluetoothDevices") as? [String] {
                devicesArray.append(sensorMACAddress!)
                UserDefaults.standard.set(devicesArray, forKey: "bluetoothDevices")
            } else {
                UserDefaults.standard.set([sensorMACAddress!], forKey: "bluetoothDevices")
            }
            bluetoothManager!.scanForPeripheral(WithName: sensorMACAddress!, WithTimeout: 15.0)
        }
    }
    
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        if isReceivingParcel {
            /* TODO: debug */
            if let bluetoothDevices = UserDefaults.standard.array(forKey: "bluetoothDevices") as? [String] {
                if let peripheralName = peripheral.name, bluetoothDevices.contains(peripheralName) {
                    bluetoothManager!.connect(peripheral: peripheral)
                }
            }
        } else {
            if let peripheralName = peripheral.name, peripheralName == sensorMACAddress! {
                bluetoothManager!.connect(peripheral: peripheral)
            }
        }
    }
    
    func bluetoothManagerFailedToDiscoverPeripheral() {
        let discoveryFailureAlertController = UIAlertController(title: nil, message: "Modum sensor device isn't in range! Please, check battery level of the sensor and make sure that sensor is operating!", preferredStyle: .alert)
        let alertControllerWithDismiss = discoveryFailureAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let sensorConnectViewController = self {
                discoveryFailureAlertController.dismiss(animated: true, completion: nil)
                _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool) {
        if isReceivingParcel {
            /* TODO: debug */
            if var bluetoothDevices = UserDefaults.standard.array(forKey: "bluetoothDevices") as? [String] {
                guard let peripheralName = peripheral.name, bluetoothDevices.contains(peripheralName) else {
                    log("Wrong peripheral connected: \(peripheral.name)")
                    bluetoothManager!.disconnect(peripheral: peripheral)
                    return
                }
                if let index = bluetoothDevices.index(of: peripheralName) {
                    bluetoothDevices.remove(at: index)
                    UserDefaults.standard.set(bluetoothDevices, forKey: "bluetoothDevices")
                }
            }
        } else {
            guard let peripheralName = peripheral.name, peripheralName == sensorMACAddress! else {
                log("Wrong peripheral connected: \(peripheral.name)")
                bluetoothManager!.disconnect(peripheral: peripheral)
                return
            }
        }
        modumSensor = ModumSensor(WithPeripheral: peripheral)
        modumSensor!.delegate = self
        modumSensor!.start()
        
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(0.3, animated: true)
            }
        }
    }
    
    // MARK: ModumSensorDelegate
    
    func modumSensorIsReady() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(0.4, animated: true)
            }
        }
        if let modumSensor = modumSensor {
            if isReceivingParcel {
                modumSensor.performSensorCheckBeforeReceiving()
            } else {
                modumSensor.performSensorCheckBeforeSending()
            }
        }
    }
    
    func modumSensorServiceUnsupported() {
        let sensorUnsupportedAlertController =  UIAlertController(title: nil, message: "Scanned device doesn't support required services! Please, try to connect to another device!", preferredStyle: .alert)
        let alertControllerWithDismiss = sensorUnsupportedAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let sensorConnectViewController = self {
                sensorUnsupportedAlertController.dismiss(animated: true, completion: nil)
                _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func modumSensorCheckBeforeSendingPerformed() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(0.5, animated: true)
                sensorConnectController.progressLabel.text = "Writing shipment data to the sensor..."
            }
        }

        /* TODO: replace dummy values with actual variables */
        let startTime = Date()
        let timeInterval: UInt8 = UInt8(1)
        
        modumSensor!.writeShipmentData(startTime: startTime, timeInterval: timeInterval, contractID: contractID!)
    }
    
    func modumSensorCheckBeforeReceivingPerformed() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(0.5, animated: true)
                sensorConnectController.progressLabel.text = "Reading shipment data from the sensor..."
            }
        }
        
        modumSensor!.downloadShipmentData()
    }
    
    func modumSensorShipmentDataWritten() {
        if let modumSensor = modumSensor {
            bluetoothManager!.disconnect(peripheral: modumSensor.sensor)
        }
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(1.0, animated: true)
                sensorConnectController.progressLabel.text = "Shipment has been successfully created!"
                
                let dispatchAfter = DispatchTime.now() + 1.0
                DispatchQueue.main.asyncAfter(deadline: dispatchAfter, execute: {
                    [weak self] in
                    
                    if let sensorConnectController = self {
                        _ = sensorConnectController.navigationController?.popToRootViewController(animated: true)
                    }
                })
            }
        }
    }
    
    func modumSensorShipmentDataReceived(startTime: Date?, measurementsCount: UInt32?, interval: UInt8?, measurements: [TemperatureMeasurement]?) {
        if let modumSensor = modumSensor {
            bluetoothManager!.disconnect(peripheral: modumSensor.sensor)
        }
        DispatchQueue.main.async {
            [weak self] in
            
            if let sensorConnectController = self {
                sensorConnectController.progressBar.setProgress(1.0, animated: true)
                sensorConnectController.progressLabel.text = "Shipment data has been successfully read!"
                
                let dispatchAfter = DispatchTime.now() + 1.0
                DispatchQueue.main.asyncAfter(deadline: dispatchAfter, execute: {
                    [weak self] in
                    
                    /* DEBUG: */
                    if let sensorConnectController = self {
                        let sensorDataAlertController = UIAlertController(title: nil, message: "Data read:\n Start Time: \(startTime?.toString(WithDateStyle: .medium, WithTimeStyle: .medium)),\nMeasurements Interval: \(interval),\nMeasurements count: \(measurementsCount)\n\nMeasurements: \(measurements?.description)", preferredStyle: .alert)
                        let alertControllerWithDismiss = sensorDataAlertController.addDismissAction(WithHandler: {
                            [weak self]
                            _ in
                            
                            if let sensorConnectViewController = self {
                                sensorDataAlertController.dismiss(animated: true, completion: nil)
                                _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                            }
                        })
                        
                        sensorConnectController.present(alertControllerWithDismiss, animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    func modumSensorErrorOccured(_ error: SensorError?) {
        if let modumSensor = modumSensor {
            bluetoothManager!.disconnect(peripheral: modumSensor.sensor)
        }
        if let error = error {
            switch error {
                case .batteryLevelTooLow:
                    let outOfBatteryAlertController = UIAlertController(title: nil, message: "Sensor battery level is too low. Please, replace battery inside the sensor and try again!", preferredStyle: .alert)
                    let alertControllerWithDismiss = outOfBatteryAlertController.addDismissAction(WithHandler: {
                        [weak self]
                        _ in
                        
                        if let sensorConnectViewController = self {
                            outOfBatteryAlertController.dismiss(animated: true, completion: nil)
                            _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    
                    present(alertControllerWithDismiss, animated: true, completion: nil)
                case .recordingAlready:
                    let sensorIsRecordingAlertController = UIAlertController(title: nil, message: "This sensor is in recording mode! Please, try to use another sensor!", preferredStyle: .alert)
                    let alertControllerWithDismiss = sensorIsRecordingAlertController.addDismissAction(WithHandler: {
                        [weak self]
                        _ in
                        
                        if let sensorConnectViewController = self {
                            sensorIsRecordingAlertController.dismiss(animated: true, completion: nil)
                            _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    
                    present(alertControllerWithDismiss, animated: true, completion: nil)
                case .selfCheckFailed:
                    let sensorBrokenAlertController = UIAlertController(title: nil, message: "The sensor is broken! Please, try to use another sensor!", preferredStyle: .alert)
                    let alertControllerWithDismiss = sensorBrokenAlertController.addDismissAction(WithHandler: {
                        [weak self]
                        _ in
                        
                        if let sensorConnectViewController = self {
                            sensorBrokenAlertController.dismiss(animated: true, completion: nil)
                            _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    
                    present(alertControllerWithDismiss, animated: true, completion: nil)
                case .serviceUnavailable:
                    let serviceUnavailableAlertController = UIAlertController(title: nil, message: "Something went wrong! Try to create shipment again or use another sensor!", preferredStyle: .alert)
                    let alertControllerWithDismiss = serviceUnavailableAlertController.addDismissAction(WithHandler: {
                        [weak self]
                        _ in
                        
                        if let sensorConnectViewController = self {
                            serviceUnavailableAlertController.dismiss(animated: true, completion: nil)
                            _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    
                    present(alertControllerWithDismiss, animated: true, completion: nil)
                case .notRecording:
                    let notRecordingAlertController = UIAlertController(title: nil, message: "Sensor isn't currently in recording mode! Please, try another sensor.", preferredStyle: .alert)
                    let alertControllerWithDismiss = notRecordingAlertController.addDismissAction(WithHandler: {
                        [weak self]
                        _ in
                        
                        if let sensorConnectViewController = self {
                            notRecordingAlertController.dismiss(animated: true, completion: nil)
                            _ = sensorConnectViewController.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    
                    present(alertControllerWithDismiss, animated: true, completion: nil)
            }
        }
    }
    
}
