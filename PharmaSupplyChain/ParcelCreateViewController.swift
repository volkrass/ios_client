//
//  ParcelCreateViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 26.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit
import CoreData
import CoreBluetooth

class ParcelCreateViewController : UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, BluetoothManagerDelegate, ModumSensorDelegate {
    
    // MARK: Properties
    
    var sensorMAC: String?
    var tntNumber: String?
    
    fileprivate var loadingView: UILoadingView?
    
    fileprivate var companyDefaults: CompanyDefaults? {
        didSet {
            categoryPickerView.reloadComponent(0)
            if let companyDefaults = companyDefaults, let measurementInterval = companyDefaults.defaultMeasurementInterval {
                measurementsIntervalLabel.text = "\(measurementInterval) minutes"
            } else {
                measurementsIntervalLabel.text = "-"
            }
            if let companyDefaults = companyDefaults, let tempCategoryIndex = companyDefaults.defaultTemperatureCategoryIndex {
                if tempCategoryIndex >= 0 && tempCategoryIndex < companyDefaults.companyTemperatureCategories.count {
                    selectedCategoryLabel.text = companyDefaults.companyTemperatureCategories[tempCategoryIndex].name ?? "Temperature Category"
                    categoryPickerView.selectRow(tempCategoryIndex, inComponent: 0, animated: false)
                } else {
                    selectedCategoryLabel.text = "Temperature Category"
                }
            } else {
                selectedCategoryLabel.text = "-"
            }
        }
    }
    
    /* parcel that will be created in case of successful sensor data write */
    fileprivate var createdParcel: CreatedParcel?
    
    /* Sensor connectivity properties */
    fileprivate var modumSensor: ModumSensor?
    fileprivate var bluetoothManager: BluetoothManager?

    // MARK: Outlets
    
    @IBOutlet weak fileprivate var parametersMainView: UIView!
    @IBOutlet weak fileprivate var selectedCategoryLabel: UILabel!
    @IBOutlet weak fileprivate var categoryPickerView: UIPickerView!
    @IBOutlet weak fileprivate var measurementsIntervalLabel: UILabel!
    @IBOutlet weak fileprivate var proceedButton: UIButton!
    
    // MARK: Actions
    
    @IBAction fileprivate func proceedButtonTouchUpInside(_ sender: UIButton) {
        if let selectedTemperatureCategory = companyDefaults?.companyTemperatureCategories[categoryPickerView.selectedRow(inComponent: 0)] {
            createdParcel!.tempCategory = TemperatureCategory()
            createdParcel!.tempCategory!.name = selectedTemperatureCategory.name
            createdParcel!.tempCategory!.minTemp = selectedTemperatureCategory.tempLow
            createdParcel!.tempCategory!.maxTemp = selectedTemperatureCategory.tempHigh
        }
        
        bluetoothManager!.start()
        showLoadingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLoadingView()
        loadingView!.setText(text: "Loading parcel information...")
        
        /* UI configuration */
        parametersMainView.layer.cornerRadius = 25.0
        parametersMainView.layer.masksToBounds = true
        proceedButton.layer.cornerRadius = 10.0
        proceedButton.layer.masksToBounds = true
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        categoryPickerView.tintColor = UIColor.blue
        
        navigationController?.navigationBar.isHidden = true
        
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
        
        /* Data validation */
        guard let tntNumber = tntNumber else {
            log("Track&Trace number is nil!")
            
            let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
            let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                [weak self]
                _ in
                
                if let parcelCreateViewController = self {
                    internalErrorAlertController.dismiss(animated: true, completion: nil)
                    _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            present(alertControllerWithDismiss, animated: true, completion: nil)
            
            return
        }
        
        guard sensorMAC != nil else {
            log("Sensor MAC address is nil!")
            
            let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
            let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                [weak self]
                _ in
                
                if let parcelCreateViewController = self {
                    internalErrorAlertController.dismiss(animated: true, completion: nil)
                    _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            present(alertControllerWithDismiss, animated: true, completion: nil)
            
            return
        }
        
        /* setup CreatedParcel object */
        createdParcel = CreatedParcel()
        createdParcel!.maxFailsTemp = 3
        createdParcel!.sensorUUID = sensorMAC
        createdParcel!.tntNumber = tntNumber
        
        /* BluetoothManager configuration */
        bluetoothManager = BluetoothManager.shared
        bluetoothManager!.delegate = self
        
        /* retrieve CompanyDefaults from CoreData */
        let companyDefaultsFetchRequest = NSFetchRequest<CDCompanyDefaults>(entityName: "CDCompanyDefaults")
        companyDefaultsFetchRequest.fetchLimit = 1
        companyDefaultsFetchRequest.predicate = NSPredicate(value: true)
        
        do {
            let companyDefaultsRecords = try CoreDataManager.shared.viewingContext.fetch(companyDefaultsFetchRequest)
            if !companyDefaultsRecords.isEmpty {
                let companyDefaults = companyDefaultsRecords[0]
                self.companyDefaults = CompanyDefaults(WithCoreDataObject: companyDefaults)
            }
        } catch {
            log("Error fetching CompanyDefaults from CoreData: \(error.localizedDescription)")
            let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
            let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                [weak self]
                _ in
                
                if let parcelCreateViewController = self {
                    internalErrorAlertController.dismiss(animated: true, completion: nil)
                    _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            present(alertControllerWithDismiss, animated: true, completion: nil)
            
            return
        }
        
        /* attempt to fetch prepared shipment details for scanned TNT. If they aren't available or there is no internet, suggest user to choose from CompanyDefaults. If those are non-available, abort sending parcel */
        ServerManager.shared.getPreparedShipment(tntNumber: "", completionHandler: {
            [weak self]
            error, preparedShipment in
            
            if let parcelCreateViewController = self {
                if error != nil {
                    parcelCreateViewController.hideLoadingView()
                } else if let preparedShipment = preparedShipment {
                    if let category = preparedShipment.temperatureCategory {
                        parcelCreateViewController.createdParcel!.tempCategory = category
                    } else {
                        let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
                        let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                            [weak self]
                            _ in
                            
                            if let parcelCreateViewController = self {
                                internalErrorAlertController.dismiss(animated: true, completion: nil)
                                _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                            }
                        })
                        
                        parcelCreateViewController.present(alertControllerWithDismiss, animated: true, completion: nil)
                    }
                    /* Connect to sensor and write data from prepared shipment */
                    parcelCreateViewController.bluetoothManager!.start()
                }
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        bluetoothManager = nil
        modumSensor = nil
    }
    
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let companyDefaults = companyDefaults else {
            return 0
        }
        return companyDefaults.companyTemperatureCategories.count
    }
    
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let companyDefaults = companyDefaults {
            let tempCategory = companyDefaults.companyTemperatureCategories[row]
            return tempCategory.name ?? "Temperature Category"
        } else {
            return "Temperature Category"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if let companyDefaults = companyDefaults {
            let tempCategory = companyDefaults.companyTemperatureCategories[row]
            let attributedTempCategory = NSAttributedString(string: tempCategory.name ?? "Temperature Category", attributes: [NSFontAttributeName : UIFont(name: "OpenSans-Light", size: 16.0)!, NSForegroundColorAttributeName : IOS7_BLUE_COLOR])
            return attributedTempCategory
        } else {
            return NSAttributedString(string: "Temperature Category")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategoryLabel.text = companyDefaults?.companyTemperatureCategories[row].name ?? "Temperature Category"
    }
    
    // MARK: BluetoothDiscoveryDelegate
    
    func bluetoothManagerBluetoothPoweredOff() {
        let noBluetoothAlertController = UIAlertController(title: nil, message: "Bluetooth is turned off. Please, turn on Bluetooth in Settings.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            [weak self]
            _ in
            
            if let parcelCreateViewController = self {
                noBluetoothAlertController.dismiss(animated: true, completion: nil)
                _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
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
            
            if let parcelCreateViewController = self {
                bluetoothUnavailableAlertController.dismiss(animated: true, completion: nil)
                _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func bluetoothManagerIsReady() {
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelCreateViewController = self, let loadingView = parcelCreateViewController.loadingView {
                loadingView.setText(text: "Scanning for Bluetooth devices...")
            }
        }
        bluetoothManager!.scanForPeripheral(WithName: sensorMAC!)
    }
    
    func bluetoothManagerDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        if let peripheralName = peripheral.name, peripheralName == sensorMAC! {
            bluetoothManager!.connect(peripheral: peripheral)
        }
    }
    
    func bluetoothManagerFailedToDiscoverPeripheral() {
        let discoveryFailureAlertController = UIAlertController(title: nil, message: "Modum sensor device isn't in range! Please, check battery level of the sensor and make sure that sensor is operating!", preferredStyle: .alert)
        let alertControllerWithDismiss = discoveryFailureAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let parcelCreateViewController = self {
                discoveryFailureAlertController.dismiss(animated: true, completion: nil)
                _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func bluetoothManagerPeripheralConnected(_ peripheral: CBPeripheral, _ success: Bool) {
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelCreateViewController = self, let loadingView = parcelCreateViewController.loadingView {
                loadingView.setText(text: "Connected to sensor!")
            }
        }
        guard let peripheralName = peripheral.name, peripheralName == sensorMAC! else {
            log("Wrong peripheral connected: \(peripheral.name)")
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
            modumSensor.performSensorCheckBeforeSending()
        }
    }
    
    func modumSensorServiceUnsupported() {
        let sensorUnsupportedAlertController =  UIAlertController(title: nil, message: "Scanned device doesn't support required services! Please, try to connect to another device!", preferredStyle: .alert)
        let alertControllerWithDismiss = sensorUnsupportedAlertController.addDismissAction(WithHandler: {
            [weak self]
            _ in
            
            if let parcelCreateViewController = self {
                sensorUnsupportedAlertController.dismiss(animated: true, completion: nil)
                _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        
        present(alertControllerWithDismiss, animated: true, completion: nil)
    }
    
    func modumSensorCheckBeforeSendingPerformed() {
        if let companyDefaults = companyDefaults, let timeInterval = companyDefaults.defaultMeasurementInterval {
            modumSensor!.writeShipmentData(startTime: Date(), timeInterval: UInt8(timeInterval), contractID: tntNumber!)
        } else {
            let internalErrorAlertController = UIAlertController(title: nil, message: "Internal error occured! Please, try again!", preferredStyle: .alert)
            let alertControllerWithDismiss = internalErrorAlertController.addDismissAction(WithHandler: {
                [weak self]
                _ in
                
                if let parcelCreateViewController = self {
                    internalErrorAlertController.dismiss(animated: true, completion: nil)
                    _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                }
            })
            
            present(alertControllerWithDismiss, animated: true, completion: nil)
        }
    }
    
    func modumSensorShipmentDataWritten() {
        if let modumSensor = modumSensor {
            bluetoothManager!.disconnect(peripheral: modumSensor.sensor)
        }
        DispatchQueue.main.async {
            [weak self] in
            
            if let parcelCreateViewController = self {
                if let loadingView = parcelCreateViewController.loadingView {
                    loadingView.setText(text: "Parcel created!")
                }
                if let createdParcel = parcelCreateViewController.createdParcel {
                    ServerManager.shared.createParcel(parcel: createdParcel, completionHandler: {
                        [weak self]
                        error, parcel in
                        
                        
                    })
                }
                
                let dispatchAfter = DispatchTime.now() + 1.0
                DispatchQueue.main.asyncAfter(deadline: dispatchAfter, execute: {
                    [weak self] in
                    
                    if let parcelCreateViewController = self {
                        _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
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
                    
                    if let parcelCreateViewController = self {
                        outOfBatteryAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .recordingAlready:
                let sensorIsRecordingAlertController = UIAlertController(title: nil, message: "This sensor is in recording mode! Please, try to use another sensor!", preferredStyle: .alert)
                let alertControllerWithDismiss = sensorIsRecordingAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelCreateViewController = self {
                        sensorIsRecordingAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .selfCheckFailed:
                let sensorBrokenAlertController = UIAlertController(title: nil, message: "The sensor is broken! Please, try to use another sensor!", preferredStyle: .alert)
                let alertControllerWithDismiss = sensorBrokenAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelCreateViewController = self {
                        sensorBrokenAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .serviceUnavailable:
                let serviceUnavailableAlertController = UIAlertController(title: nil, message: "Something went wrong! Try to create shipment again or use another sensor!", preferredStyle: .alert)
                let alertControllerWithDismiss = serviceUnavailableAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelCreateViewController = self {
                        serviceUnavailableAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            case .notRecording:
                let notRecordingAlertController = UIAlertController(title: nil, message: "Sensor isn't currently in recording mode! Please, try another sensor.", preferredStyle: .alert)
                let alertControllerWithDismiss = notRecordingAlertController.addDismissAction(WithHandler: {
                    [weak self]
                    _ in
                    
                    if let parcelCreateViewController = self {
                        notRecordingAlertController.dismiss(animated: true, completion: nil)
                        _ = parcelCreateViewController.navigationController?.popToRootViewController(animated: true)
                    }
                })
                
                present(alertControllerWithDismiss, animated: true, completion: nil)
            }
        }
    }
    
    func modumSensorCheckBeforeReceivingPerformed() {
        /* Protocol requirement */
    }
    
    func modumSensorShipmentDataReceived(startTime: Date?, measurementsCount: UInt32?, interval: UInt8?, measurements: [CounterBasedMeasurement]?) {
        /* Protocol requirement */
    }
    
    // MARK: Helper functions
    
    fileprivate func showLoadingView() {
        loadingView = UILoadingView(rect: parametersMainView.bounds)
        loadingView!.startAnimating()
        parametersMainView.addSubview(loadingView!)
        parametersMainView.bringSubview(toFront: loadingView!)
    }
    
    fileprivate func hideLoadingView() {
        if let loadingView = loadingView {
            loadingView.removeFromSuperview()
        }
        loadingView = nil
    }
    
}
