//
//  ModumSensor.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol ModumSensorDelegate {
    
    func modumSensorIsReady()
    func modumSensorServiceUnsupported()
    func modumSensorErrorOccured(_ error: SensorError?)
    func modumSensorCheckBeforeSendingPerformed()
    func modumSensorCheckBeforeReceivingPerformed()
    func modumSensorShipmentDataWritten()
    func modumSensorShipmentDataReceived(startTime: Date?, measurementsCount: UInt32?, interval: UInt8?, measurements: [CounterBasedMeasurement]?)
    func modumSensorAbortSendingCompleted()
    
}

enum SensorError: Error {
    case batteryLevelTooLow
    case recordingAlready
    case selfCheckFailed
    case serviceUnavailable
    case notRecording
    case connectionError
    case abortSendingFailed
}

/* Class responsible for communication with Modum sensor device */
class ModumSensor : NSObject, CBPeripheralDelegate {
    
    // MARK: Properties
    
    var delegate: ModumSensorDelegate?
    
    var sensor: CBPeripheral
    
    fileprivate var sensorBeforeSendCheck: SensorBeforeSendCheck?
    fileprivate var sensorBeforeReceiveCheck: SensorBeforeReceiveCheck?
    fileprivate var sensorDataWritten: SensorDataWritten?
    
    fileprivate var sensorDataRead: SensorDataRead?
    
    /* Helper variables */
    fileprivate var charsForBatteryLevelServiceDiscovered: Bool = false
    fileprivate var charsForSensorServiceDiscovered: Bool = false
    
    /* Helper variables for reading out shipment data value from the sensor */
    fileprivate var startTime: Date?
    fileprivate var measurementsInterval: UInt8?
    fileprivate var measurementsCount: UInt32?
    fileprivate var measurementsIndex: UInt32?
    fileprivate var measurements: [CounterBasedMeasurement]?
    
    /**********  Characteristics **********/
    
    fileprivate var batteryLevelCharacteristic: CBCharacteristic?
    fileprivate var contractIDCharacteristic: CBCharacteristic?
    fileprivate var startTimeCharacteristic: CBCharacteristic?
    fileprivate var measurementsCharacteristic: CBCharacteristic?
    fileprivate var measurementsCountCharacteristic: CBCharacteristic?
    fileprivate var measurementsIndexCharacteristic: CBCharacteristic?
    fileprivate var recordingTimeIntervalCharacteristic: CBCharacteristic?
    fileprivate var isRecordingCharacteristic: CBCharacteristic?
    
    /********** Internal state structures **********/
    
    /*
     Struct that tracks the check of sensor characteristics before writing shipment data to the sensor
     */
    fileprivate struct SensorBeforeSendCheck {
        
        // MARK: Constants
        
        static let notificationName: String = "SensorBeforeSendCheck"
        
        var checkedBatteryLevel: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var checkedIsRecording: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        fileprivate func checkProgress() {
            if checkedIsRecording && checkedBatteryLevel {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SensorBeforeSendCheck.notificationName), object: nil)
            }
        }
        
    }
    
    /*
     Struct that tracks the check of sensor characteristics before reading shipment data from the sensor
     */
    fileprivate struct SensorBeforeReceiveCheck {
        
        // MARK: Constants
        
        static let notificationName: String = "SensorBeforeReceiveCheck"
        
        var checkedIsRecording: Bool = false {
            didSet {
                if checkedIsRecording {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: SensorBeforeReceiveCheck.notificationName), object: nil)
                }
            }
        }
        
    }
    
    /*
     Struct that tracks the status of reading shipment data from the sensor and
     sends out notification once the read process is done
     */
    fileprivate struct SensorDataRead {
        
        // MARK: Constants
        
        static let notificationName: String = "SensorDataRead"
        
        // MARK: Properties
        
        var didWriteIsRecording: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didReadMeasurementsCount: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didReadMeasurements: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didReadStartTime: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didReadTimeInterval: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        fileprivate func checkProgress() {
            if didReadMeasurementsCount && didReadMeasurements && didReadStartTime && didReadTimeInterval {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SensorDataRead.notificationName), object: nil)
            }
        }
    }
    
    /*
     Struct that tracks the status of writing shipment data to the sensor and
     sends out notification once the write process is done
     */
    fileprivate struct SensorDataWritten {
        
        // MARK: Constants
        
        static let notificationName: String = "SensorDataWritten"
        
        // MARK: Properties
        
        var didWriteContractID: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didCheckSensorState: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didWriteStartTime: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didWriteTimeInterval: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        var didWriteIsRecording: Bool = false {
            didSet {
                checkProgress()
            }
        }
        
        fileprivate func checkProgress() {
            if didWriteContractID && didWriteStartTime && didWriteTimeInterval && didWriteIsRecording && didCheckSensorState {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SensorDataWritten.notificationName), object: nil)
            }
        }
    }
    
    // MARK: Constants
    
    /* sensor should have at least 30% of battery before sending process */
    static let MIN_BATTERY_LEVEL: Int = 30
    
    /**********  Services UUIDs **********/
    
    fileprivate let batteryLevelServiceUUID: CBUUID = CBUUID(string: "0000180f-0000-1000-8000-00805f9b34fb")
    fileprivate let sensorServiceUUID: CBUUID = CBUUID(string: "f000aa00-0451-4000-b000-000000000000")
    
    /********** Characteristics UUIDs **********/
    
    /* sensor battery level characterstic UUID, in % */
    fileprivate let batteryLevelUUID: CBUUID = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb")
    
    /* characteristic from where the actual measurements are read */
    fileprivate let measurementsUUID: CBUUID = CBUUID(string: "f000aa01-0451-4000-b000-000000000000")
    
    /* characteristic determining whether sensor is currently recording */
    fileprivate let isRecordingUUID: CBUUID = CBUUID(string: "f000aa02-0451-4000-b000-000000000000")
    
    /* characteristic determining how often sensor takes measurements (in <units>)*/
    fileprivate let recordingTimeIntervalUUID: CBUUID = CBUUID(string: "f000aa03-0451-4000-b000-000000000000")
    
    /* characteristic determining how many temperature measurements are there (in <units>) */
    fileprivate let measurementsCountUUID: CBUUID = CBUUID(string: "f000aa04-0451-4000-b000-000000000000")
    
    /* characteristic determining the index to the temperature measurements array */
    fileprivate let measurementsIndexUUID: CBUUID = CBUUID(string: "f000aa05-0451-4000-b000-000000000000")
    
    /* smart contract ID characteristic UUID */
    fileprivate let contractIDUUID: CBUUID = CBUUID(string: "f000aa06-0451-4000-b000-000000000000")
    
    /* characteristic determining the start time of recording */
    fileprivate let startTimeUUID: CBUUID = CBUUID(string: "f000aa07-0451-4000-b000-000000000000")
    
    init(WithPeripheral peripheral: CBPeripheral) {
        sensor = peripheral

        super.init()
        
        sensor.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Public functions
    
    func start() {
        /* subscribing to notifications */
        NotificationCenter.default.addObserver(self, selector: #selector(sensorBeforeSendCheckFinished), name: NSNotification.Name(rawValue: SensorBeforeSendCheck.notificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sensorBeforeReceiveCheckFinished), name: NSNotification.Name(rawValue: SensorBeforeReceiveCheck.notificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sensorDataFinishedRead), name: NSNotification.Name(rawValue: SensorDataRead.notificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sensorDataFinishedWrite), name: NSNotification.Name(rawValue: SensorDataWritten.notificationName), object: nil)
        
        if let services = sensor.services, !services.isEmpty {
            let serviceUUIDs = services.map {$0.uuid}
            guard serviceUUIDs.contains(Array: [batteryLevelServiceUUID, sensorServiceUUID]) else {
                log("Given peripheral \(sensor.description) doesn't expose required services.")
                if let delegate = delegate {
                    delegate.modumSensorServiceUnsupported()
                }
                return
            }
            for service in services {
                switch service.uuid {
                    case batteryLevelServiceUUID:
                        sensor.discoverCharacteristics([batteryLevelUUID], for: service)
                    case sensorServiceUUID:
                        sensor.discoverCharacteristics([measurementsUUID, isRecordingUUID, recordingTimeIntervalUUID, measurementsCountUUID, measurementsIndexUUID, contractIDUUID, startTimeUUID], for: service)
                    default:
                        break
                }
            }
        } else {
            sensor.discoverServices([batteryLevelServiceUUID, sensorServiceUUID])
        }
    }
    
    /*
     Assures that the sensor battery level is sufficient and whether sensor isn't recording before initializing send operation
     */
    func performSensorCheckBeforeSending() {
        if let batteryLevelCharacteristic = batteryLevelCharacteristic, let isRecordingCharacteristic = isRecordingCharacteristic {
            sensor.readValue(for: batteryLevelCharacteristic)
            sensor.readValue(for: isRecordingCharacteristic)
            sensorBeforeSendCheck = SensorBeforeSendCheck()
        } else {
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
        }
    }
    
    /*
     Assure that sensor is recording before downloading shipment datas
     */
    func performSensorCheckBeforeReceiving() {
        if let isRecordingCharacteristic = isRecordingCharacteristic {
            sensorBeforeReceiveCheck = SensorBeforeReceiveCheck()
            sensor.readValue(for: isRecordingCharacteristic)
        } else {
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
        }
    }
    
    /*
     Writes data for the shipment into the sensor
     */
    func writeShipmentData(startTime: Date, timeInterval: UInt8, contractID: String) {
        sensorDataWritten = SensorDataWritten()
        writeStartTime(startTime)
        writeContractId(contractID)
        writeRecordingTimeInterval(timeInterval)
        writeIsRecording(true)
    }
    
    /*
     Downloads data related to the shipment from the sensor
     */
    func downloadShipmentData() {
        if let startTimeCharacteristic = startTimeCharacteristic, let recordingTimeIntervalCharacteristic = recordingTimeIntervalCharacteristic, let measurementsCountCharacteristic = measurementsCountCharacteristic {
            sensorDataRead = SensorDataRead()
            measurementsIndex = nil
            measurementsCount = nil
            measurements = nil
            
            writeIsRecording(false)
            sensor.readValue(for: measurementsCountCharacteristic)
            sensor.readValue(for: startTimeCharacteristic)
            sensor.readValue(for: recordingTimeIntervalCharacteristic)
        } else {
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
        }
    }
    
    /* if server error occured (for example, parcel with such TNT already exists), abort sending */
    func abortSending() {
        if let isRecordingCharacteristic = isRecordingCharacteristic {
            writeIsRecording(false)
        }
    }
    
    // MARK: CBPeriperhalDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            log("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard peripheral == sensor else {
            log("Discovered services for wrong peripheral \(peripheral.name ?? "-")")
            return
        }
        
        if let services = peripheral.services, !services.isEmpty {
            let servicesUUIDs = services.map {$0.uuid}
            guard servicesUUIDs.contains(Array: [batteryLevelServiceUUID, sensorServiceUUID]) else {
                log("Given peripheral \(sensor.description) doesn't expose required services.")
                if let delegate = delegate {
                    delegate.modumSensorServiceUnsupported()
                }
                return
            }
            
            for service in services {
                switch service.uuid {
                    case batteryLevelServiceUUID:
                        sensor.discoverCharacteristics([batteryLevelUUID], for: service)
                    case sensorServiceUUID:
                        sensor.discoverCharacteristics([measurementsUUID, isRecordingUUID, recordingTimeIntervalUUID, measurementsCountUUID, measurementsIndexUUID, contractIDUUID, startTimeUUID], for: service)
                    default:
                        break
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            log("Error discovering characteristics: \(error!.localizedDescription)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        guard peripheral == sensor else {
            log("Discovered service characteristics for wrong peripheral \(peripheral.name ?? "-")")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        guard service.uuid == sensorServiceUUID || service.uuid == batteryLevelServiceUUID else {
            log("Discovered characteristics for wrong service \(service.description)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        
        if service.uuid == batteryLevelServiceUUID {
            charsForBatteryLevelServiceDiscovered = true
        } else if service.uuid == sensorServiceUUID {
            charsForSensorServiceDiscovered = true
        }
        
        if let characteristics = service.characteristics {
            characteristics.forEach({
                characteristic in
                
                switch characteristic.uuid {
                    case batteryLevelUUID:
                        batteryLevelCharacteristic = characteristic
                    case recordingTimeIntervalUUID:
                        recordingTimeIntervalCharacteristic = characteristic
                    case contractIDUUID:
                        contractIDCharacteristic = characteristic
                    case measurementsUUID:
                        measurementsCharacteristic = characteristic
                    case measurementsCountUUID:
                        measurementsCountCharacteristic = characteristic
                    case measurementsIndexUUID:
                        measurementsIndexCharacteristic = characteristic
                    case isRecordingUUID:
                        isRecordingCharacteristic = characteristic
                    case startTimeUUID:
                        startTimeCharacteristic = characteristic
                    default:
                        break
                }
            })
        }
        
        if let delegate = delegate, (charsForSensorServiceDiscovered && charsForBatteryLevelServiceDiscovered) {
            if allCharacteriticsDiscovered() {
                delegate.modumSensorIsReady()
            } else {
                delegate.modumSensorServiceUnsupported()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral == sensor else {
            log("Received write indication for wrong peripheral \(peripheral.name ?? "-")")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        guard characteristic.service.uuid == sensorServiceUUID || characteristic.service.uuid == batteryLevelServiceUUID else {
            log("Received write indication for wrong service \(characteristic.service.description)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        
        switch characteristic.uuid {
            case contractIDUUID:
                if let error = error {
                    log("Failed to write contract ID: \(error.localizedDescription)")
                    if let delegate = delegate {
                        delegate.modumSensorErrorOccured(.connectionError)
                    }
                } else {
                    if sensorDataWritten != nil {
                        sensorDataWritten!.didWriteContractID = true
                    }
                }
            case isRecordingUUID:
                if let error = error {
                    log("Failed to write isRecording flag: \(error.localizedDescription)")
                    if let delegate = delegate {
                        delegate.modumSensorErrorOccured(.connectionError)
                    }
                } else {
                    if sensorDataWritten != nil {
                        sensorDataWritten!.didWriteIsRecording = true
                        /* when writing data to the sensor, perform self-check */
                        sensor.readValue(for: characteristic)
                    } else if sensorDataRead != nil {
                        sensorDataRead!.didWriteIsRecording = true
                    }
                }
            case startTimeUUID:
                if let error = error {
                    log("Failed to write startTime: \(error.localizedDescription)")
                    if let delegate = delegate {
                        delegate.modumSensorErrorOccured(.connectionError)
                    }
                } else {
                    if sensorDataWritten != nil {
                        sensorDataWritten!.didWriteStartTime = true
                    }
                }
            case recordingTimeIntervalUUID:
                if let error = error {
                    log("Failed to write recording time interval: \(error.localizedDescription)")
                    if let delegate = delegate {
                        delegate.modumSensorErrorOccured(.connectionError)
                    }
                } else {
                    if sensorDataWritten != nil {
                        sensorDataWritten!.didWriteTimeInterval = true
                    }
                }
            case measurementsIndexUUID:
                if let error = error {
                    log("Failed to write measurements read index: \(error.localizedDescription)")
                    if let delegate = delegate {
                        delegate.modumSensorErrorOccured(.connectionError)
                    }
                } else {
                    if let measurementsCharacteristic = measurementsCharacteristic {
                        sensor.readValue(for: measurementsCharacteristic)
                    }
                }
            default:
                break
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            log("Error updating value for characteristic: \(characteristic.description): \((error! as NSError).userInfo)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        guard peripheral == sensor else {
            log("Updated value for characteristic on wrong peripheral: \(peripheral.name ?? "-")")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        guard characteristic.service.uuid == sensorServiceUUID || characteristic.service.uuid == batteryLevelServiceUUID else {
            log("Updated characteristic value for wrong service: \(characteristic.service.description)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.connectionError)
            }
            return
        }
        
        switch characteristic.uuid {
            case batteryLevelUUID:
                if let batteryLevelValue = characteristic.value, !batteryLevelValue.isEmpty {
                    let batteryLevel = Int(batteryLevelValue[0])
                    if sensorBeforeSendCheck != nil {
                        sensorBeforeSendCheck!.checkedBatteryLevel = true
                    } 
                    if let delegate = delegate, batteryLevel <= ModumSensor.MIN_BATTERY_LEVEL {
                        delegate.modumSensorErrorOccured(.batteryLevelTooLow)
                    }
                }
            case contractIDUUID:
                if let contractIDValue = characteristic.value, !contractIDValue.isEmpty {
                    /* handling zero-terminated string */
                    var contractIDBytes: [UInt8] = []
                    for byte in contractIDValue {
                        if byte != 0 {
                            contractIDBytes.append(byte)
                        } else {
                            break
                        }
                    }
                    let contractIDData = Data(bytes: contractIDBytes)
                    _ = String(data: contractIDData, encoding: .utf8)
                    
                    /* Characteristic is currently not in use */
                }
            case isRecordingUUID:
                if let isRecordingValue = characteristic.value, !isRecordingValue.isEmpty {
                    let isRecording: UInt8 = isRecordingValue[0]
                    if sensorBeforeSendCheck != nil {
                        sensorBeforeSendCheck!.checkedIsRecording = true
                        if let delegate = delegate, isRecording == 0x01 {
                            delegate.modumSensorErrorOccured(.recordingAlready)
                        }
                    } else if sensorBeforeReceiveCheck != nil {
                        sensorBeforeReceiveCheck!.checkedIsRecording = true
                        if let delegate = delegate, isRecording == 0x00 {
                            delegate.modumSensorErrorOccured(.notRecording)
                        }
                    } else if sensorDataWritten != nil {
                        if let delegate = delegate, isRecording == 0xFF {
                            delegate.modumSensorErrorOccured(.selfCheckFailed)
                        }
                        sensorDataWritten!.didCheckSensorState = true
                    }
                }
            case measurementsCountUUID:
                if let measurementsCountValue = characteristic.value, !measurementsCountValue.isEmpty {
                    
                    measurementsCount = UInt32(littleEndian: measurementsCountValue.withUnsafeBytes { $0.pointee })
                    measurementsIndex = 0
                    
                    if sensorDataRead != nil {
                        sensorDataRead!.didReadMeasurementsCount = true
                    }
                    
                    if measurementsCount! > 0 {
                        writeMeasurementsIndex(measurementsIndex!)
                    }
            }
            case measurementsUUID:
                if let measurementsValue = characteristic.value {
                    guard measurementsValue != Data(bytes: [0x0]) else {
                        log("No measurements recorded!")
                        if sensorDataRead != nil {
                            sensorDataRead!.didReadMeasurements = true
                        }
                        break
                    }
                    let temperatureMeasurements = CounterBasedMeasurement.measurementsFromData(data: measurementsValue)
                    if !temperatureMeasurements.isEmpty {
                        if measurements == nil {
                            measurements = []
                        }
                        measurements!.append(contentsOf: temperatureMeasurements)
                        if let measurementsCount = measurementsCount, measurements!.count >= Int(measurementsCount) {
                            log("Finished reading temperature measurements")
                            log("Temperature measurements are: \(measurements!)")
                            if sensorDataRead != nil {
                                sensorDataRead!.didReadMeasurements = true
                            }
                        } else {
                            self.measurementsIndex = self.measurementsIndex! + UInt32(temperatureMeasurements.count)
                            writeMeasurementsIndex(measurementsIndex!)
                        }
                    }
                }
                break
            case startTimeUUID:
                if let startTimeValue = characteristic.value, !startTimeValue.isEmpty {
                    let timeInterval: TimeInterval = startTimeValue.withUnsafeBytes{ $0.pointee }
                    startTime = Date(timeIntervalSince1970: timeInterval)
                    
                    if sensorDataRead != nil {
                        sensorDataRead!.didReadStartTime = true
                    }
                }
                break
            case recordingTimeIntervalUUID:
                if let recordingTimeIntervalValue = characteristic.value, !recordingTimeIntervalValue.isEmpty {
                    
                    self.measurementsInterval = recordingTimeIntervalValue[0]
                    
                    if sensorDataRead != nil {
                        sensorDataRead!.didReadTimeInterval = true
                    }
                }
                break
            default:
                break
        }
    }
    
    // MARK: Characteristics Interaction
    
    fileprivate func writeContractId(_ contractID: String) {
        guard let contractIDCharacteristic = contractIDCharacteristic else {
            log("No contract ID characteristic with UUID: \(contractIDUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        if var contractIDData = contractID.data(using: .utf8) {
            contractIDData.append(0)
            
            sensor.writeValue(contractIDData, for: contractIDCharacteristic, type: .withResponse)
        }
    }
    
    fileprivate func writeIsRecording(_ isRecording: Bool) {
        guard let isRecordingCharacteristic = isRecordingCharacteristic else {
            log("No isRecording characteristic with UUID: \(isRecordingUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        let isRecordingValue: Data = isRecording ? Data(bytes: [0x01] as [UInt8]) : Data(bytes: [0x00] as [UInt8])
        sensor.writeValue(isRecordingValue, for: isRecordingCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeStartTime(_ startTime: Date) {
        guard let startTimeCharacteristic = startTimeCharacteristic else {
            log("No startTime characteristic with UUID: \(startTimeUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        var timeInterval = startTime.timeIntervalSince1970
        let startTimeData = Data(bytes: &timeInterval, count: MemoryLayout<TimeInterval>.size)
        
        sensor.writeValue(startTimeData, for: startTimeCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeRecordingTimeInterval(_ timeInterval: UInt8) {
        guard let recordingTimeIntervalCharacteristic = recordingTimeIntervalCharacteristic else {
            log("No recordingTimeInterval characteristic with UUID: \(recordingTimeIntervalUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        
        let timeIntervalData = Data(bytes: [timeInterval])
        sensor.writeValue(timeIntervalData, for: recordingTimeIntervalCharacteristic, type: .withResponse)
    }
    
    fileprivate func writeMeasurementsIndex(_ index: UInt32) {
        guard let measurementsIndexCharacteristic = measurementsIndexCharacteristic else {
            log("No measurements index characteristic with UUID: \(measurementsIndexUUID)")
            if let delegate = delegate {
                delegate.modumSensorErrorOccured(.serviceUnavailable)
            }
            return
        }
        var readoutIndex = UInt32(littleEndian: index)
        let readoutIndexBytes = withUnsafePointer(to: &readoutIndex, {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt32>.size) {
                UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt32>.size)
            }
        })
        let readoutIndexData = Data(bytes: Array(readoutIndexBytes))
        sensor.writeValue(readoutIndexData, for: measurementsIndexCharacteristic, type: .withResponse)
    }
    
    // MARK: Helper functions
    
    @objc fileprivate func sensorBeforeSendCheckFinished() {
        sensorBeforeSendCheck = nil
        if let delegate = delegate {
            delegate.modumSensorCheckBeforeSendingPerformed()
        }
    }
    
    @objc fileprivate func sensorBeforeReceiveCheckFinished() {
        sensorBeforeReceiveCheck = nil
        if let delegate = delegate {
            delegate.modumSensorCheckBeforeReceivingPerformed()
        }
    }
    
    @objc fileprivate func sensorDataFinishedWrite() {
        sensorDataWritten = nil
        if let delegate = delegate {
            delegate.modumSensorShipmentDataWritten()
        }
    }
    
    @objc fileprivate func sensorDataFinishedRead() {
        sensorDataRead = nil
        if let delegate = delegate {
            delegate.modumSensorShipmentDataReceived(startTime: startTime, measurementsCount: measurementsCount, interval: measurementsInterval, measurements: measurements)
        }
    }
    
    fileprivate func allCharacteriticsDiscovered() -> Bool {
        return contractIDCharacteristic         != nil &&
            startTimeCharacteristic             != nil &&
            batteryLevelCharacteristic          != nil &&
            measurementsCharacteristic          != nil &&
            measurementsCountCharacteristic     != nil &&
            measurementsIndexCharacteristic     != nil &&
            recordingTimeIntervalCharacteristic != nil &&
            isRecordingCharacteristic           != nil
    }
    
}
