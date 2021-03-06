//
//  ParcelReceiveViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit
import CoreBluetooth

class ParcelReceiveViewController : UIViewController, BluetoothManagerDelegate, ModumSensorDelegate {
    
    // MARK: Properties
    
    var tntNumber: String?
    
    /* Information about sensor received from server */
    fileprivate var sensor: Sensor?
    
    fileprivate var loadingView: UILoadingView?
    
    /* Sensor connectivity properties */
    fileprivate var modumSensor: ModumSensor?
    fileprivate var bluetoothManager: BluetoothManager?
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var mainView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLoadingView()
        loadingView!.setText(text: "Fetching sensor information...")
        
        /* UI configuration */
        mainView.layer.cornerRadius = 25.0
        mainView.layer.masksToBounds = true
        
        /* adding gradient background */
        let leftColor = TEMPERATURE_LIGHT_BLUE.cgColor
        let middleColor = ROSE_COLOR.cgColor
        let rightColor = LIGHT_BLUE_COLOR.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [leftColor, middleColor, rightColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        /* BluetoothManager configuration */
        bluetoothManager = BluetoothManager.shared
        bluetoothManager!.delegate = self
        
        /* Data validation */
        guard let tntNumber = tntNumber else {
            log("Track&Trace number is nil!")
            
            let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
            let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                [weak self]
                _ in
                
                if let parcelReceiveViewController = self {
                    internalErrorAlertController.dismiss(animated: true, completion: nil)
                    _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            present(alertControllerWithDismiss, animated: true, completion: nil)
            
            return
        }
        
        ServerManager.shared.getSensorIDArrayForParcel(tntNumber: tntNumber, completionHandler: {
            [weak self]
            error, sensorArray in
            
            if let parcelReceiveViewController = self {
                if error != nil {
                    let alertController = UIAlertController(title: nil, message: "Failed to find sensor information! Please, try again later!", preferredStyle: .alert)
                    let alertControllerWithDismiss = alertController.addDismissAction(WithHandler: {
                        [weak self]
                        _ in
                        
                        if let parcelReceiveViewController = self {
                            alertController.dismiss(animated: true, completion: nil)
                            _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                    
                    parcelReceiveViewController.present(alertControllerWithDismiss, animated: true, completion: nil)
                } else if let sensorArray = sensorArray {
                    if !sensorArray.isEmpty {
                        parcelReceiveViewController.sensor = sensorArray[0]
                        parcelReceiveViewController.bluetoothManager!.start()
                    } else {
                        let sensorDataNotFoundAlertController = UIAlertController(title: nil, message: "Sensor data isn't found on the server!", preferredStyle: .alert)
                        let alertControllerWithDismiss = sensorDataNotFoundAlertController.addDismissAction(WithHandler: {
                            [weak self]
                            _ in
                            
                            if let parcelReceiveViewController = self {
                                sensorDataNotFoundAlertController.dismiss(animated: true, completion: nil)
                                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                            }
                        })
                        
                        parcelReceiveViewController.present(alertControllerWithDismiss, animated: true, completion: nil)
                    }
                }
            }
        })
    }
    
    // MARK: BluetoothDiscoveryDelegate
    
    func bluetoothManagerBluetoothPoweredOff() {
        let noBluetoothAlertController = UIAlertController(title: nil, message: "Bluetooth is turned off. Please, turn on Bluetooth in Settings.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            [weak self]
            _ in
            
            if let parcelReceiveViewController = self {
                noBluetoothAlertController.dismiss(animated: true, completion: nil)
                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
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
            
            if let parcelReceiveViewController = self {
                bluetoothUnavailableAlertController.dismiss(animated: true, completion: nil)
                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func bluetoothManagerIsReady() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelReceiveViewController = self, let loadingView = parcelReceiveViewController.loadingView {
                loadingView.setText(text: "Scanning for Bluetooth devices...")
            }
        }
        if let sensor = sensor, let sensorMAC = sensor.sensorMAC {
            bluetoothManager!.scanForPeripheral(WithName: sensorMAC)
        }
    }
    
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        if let peripheralName = peripheral.name, sensor!.sensorMAC! == peripheralName {
            bluetoothManager!.connect(peripheral: peripheral)
        }
    }
    
    func bluetoothManagerFailedToDiscoverPeripheral() {
        let discoveryFailureAlertController = UIAlertController(title: nil, message: "Modum sensor device isn't in range! Please, check battery level of the sensor and make sure that sensor is operating!", preferredStyle: .alert)
        let alertControllerWithDismiss = discoveryFailureAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let parcelReceiveViewController = self {
                discoveryFailureAlertController.dismiss(animated: true, completion: nil)
                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool) {
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelReceiveViewController = self, let loadingView = parcelReceiveViewController.loadingView {
                loadingView.setText(text: "Connected to sensor!")
            }
        }
        guard let peripheralName = peripheral.name, peripheralName == sensor!.sensorMAC! else {
            log("Wrong peripheral connected: \(peripheral.name ?? "<no_name>")")
            bluetoothManager!.disconnect(peripheral: peripheral)
            return
        }
        modumSensor = ModumSensor(WithPeripheral: peripheral)
        modumSensor!.delegate = self
        modumSensor!.start()
    }
    
    // MARK: ModumSensorDelegate
    
    func modumSensorIsReady() {
        if let modumSensor = modumSensor {
            modumSensor.performSensorCheckBeforeReceiving()
        }
    }
    
    func modumSensorServiceUnsupported() {
        let sensorUnsupportedAlertController =  UIAlertController(title: nil, message: "Scanned device doesn't support required services! Please, try to connect to another device!", preferredStyle: .alert)
        let alertControllerWithDismiss = sensorUnsupportedAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let parcelReceiveViewController = self {
                sensorUnsupportedAlertController.dismiss(animated: true, completion: nil)
                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func modumSensorCheckBeforeSendingPerformed() {
        /* Protocol requirement */
    }
    
    func modumSensorShipmentDataWritten() {
        /* Protocol requirement */
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
                    
                    if let parcelReceiveViewController = self {
                        outOfBatteryAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .serviceUnavailable:
                let serviceUnavailableAlertController = UIAlertController(title: nil, message: "Something went wrong! Try to create shipment again or use another sensor!", preferredStyle: .alert)
                let alertControllerWithDismiss = serviceUnavailableAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelReceiveViewController = self {
                        serviceUnavailableAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .notRecording:
                let notRecordingAlertController = UIAlertController(title: nil, message: "Sensor isn't currently in recording mode! Please, try another sensor.", preferredStyle: .alert)
                let alertControllerWithDismiss = notRecordingAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelReceiveViewController = self {
                        notRecordingAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .connectionError:
                let connectionErrorAlertController = UIAlertController(title: nil, message: "Connection to the sensor has failed! Please, try again", preferredStyle: .alert)
                let alertControllerWithDismiss = connectionErrorAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelReceiveViewController = self {
                        connectionErrorAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .abortSendingFailed, .recordingAlready, .selfCheckFailed:
                /* These errors can occur only during initiating parcel send */
                break
            }
        }
    }
    
    func modumSensorCheckBeforeReceivingPerformed() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelReceiveViewController = self, let loadingView = parcelReceiveViewController.loadingView {
                loadingView.setText(text: "Downloading data from sensor...")
            }
        }
        modumSensor!.downloadShipmentData()
    }
    
    func modumSensorShipmentDataReceived(startTime: Date?, measurementsCount: UInt32?, interval: UInt8?, measurements: [CounterBasedMeasurement]?) {
        if let modumSensor = modumSensor {
            bluetoothManager!.disconnect(peripheral: modumSensor.sensor)
        }
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelReceiveViewController = self {
                if let loadingView = parcelReceiveViewController.loadingView {
                    loadingView.setText(text: "Uploading measurements...")
                }
                /* uploading measurements data to server */
                if let startTime = startTime, let interval = interval, let measurements = measurements, let tempCategory =  parcelReceiveViewController.sensor?.tempCategory {
                    if let temperatureMeasurementsObject = TemperatureMeasurementsObject(timeInterval: Int(interval), startDate: startTime, measurements: measurements, tempCategory: tempCategory) {
                        ServerManager.shared.postTemperatureMeasurements(tntNumber: parcelReceiveViewController.tntNumber!, sensorID: parcelReceiveViewController.sensor!.sensorMAC!, measurements: temperatureMeasurementsObject, backgroundUpload: false, completionHandler: {
                            [weak self]
                            error, measurementsObject in
                            
                            if let parcelReceiveViewController = self {
                                if let error = error {
                                    if error == ServerError.defaultError || error == ServerError.noInternet {
                                        parcelReceiveViewController.loadingView?.setText(text: "Failed uploading measurements to the server! Adding upload to background...")
                                        parcelReceiveViewController.loadingView?.stopAnimating()
                                        RecurrentUploader.shared.addMeasurementsToUpload(tntNumber: parcelReceiveViewController.tntNumber!, sensorMAC: parcelReceiveViewController.sensor!.sensorMAC!, measurements: temperatureMeasurementsObject)
                                    } else if error == ServerError.parcelWithTntNotExists {
                                        let parcelWithTntNotExistsAlertController = UIAlertController(title: nil, message: "Parcel with TNT \(parcelReceiveViewController.tntNumber!) is not found on server! Measurements are still saved!", preferredStyle: .alert)
                                        let alertControllerWithDismiss = parcelWithTntNotExistsAlertController.addDismissAction(WithHandler: {
                                            [weak self]
                                            _ in
                                            
                                            if let parcelReceiveViewController = self {
                                                parcelWithTntNotExistsAlertController.dismiss(animated: true, completion: nil)
                                                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                                            }
                                        })
                                        
                                        parcelReceiveViewController.present(alertControllerWithDismiss, animated: true, completion: nil)
                                    } else if error == ServerError.measurementsForParcelAlreadyExist {
                                        let measurementsForParcelExistAlertController = UIAlertController(title: nil, message: "Measurements have already been uploaded for the parcel with \(parcelReceiveViewController.tntNumber!)!", preferredStyle: .alert)
                                        let alertControllerWithDismiss = measurementsForParcelExistAlertController.addDismissAction(WithHandler: {
                                            [weak self]
                                            _ in
                                            
                                            if let parcelReceiveViewController = self {
                                                measurementsForParcelExistAlertController.dismiss(animated: true, completion: nil)
                                                _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                                            }
                                        })
                                        
                                        parcelReceiveViewController.present(alertControllerWithDismiss, animated: true, completion: nil)
                                    }
                                } else {
                                    parcelReceiveViewController.loadingView?.setText(text: "Uploaded measurements successfully!")
                                }
                                let after = DispatchTime.now() + 1.5
                                DispatchQueue.main.asyncAfter(deadline: after, execute: {
                                    [weak self] in
                                    
                                    if let parcelReceiveViewController = self {
                                        _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                                    }
                                })
                            }
                        })
                    }
                } else {
                    _ = parcelReceiveViewController.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    func modumSensorAbortSendingCompleted() {
        /* Protocol requirement */
    }
    
    // MARK: Helper functions
    
    fileprivate func showLoadingView() {
        loadingView = UILoadingView(rect: mainView.bounds)
        loadingView!.startAnimating()
        mainView.addSubview(loadingView!)
        mainView.bringSubview(toFront: loadingView!)
    }
    
    fileprivate func hideLoadingView() {
        if let loadingView = loadingView {
            loadingView.removeFromSuperview()
        }
        loadingView = nil
    }
    
}
