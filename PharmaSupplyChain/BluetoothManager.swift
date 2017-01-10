//
//  BluetoothManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 10.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

class BluetoothManager {
    
    // MARK: Properties
    
    fileprivate var characteristics: [CBCharacteristic] = []
    
    // MARK: Constants
    
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
    fileprivate let measurementsReadIndexUUID: CBUUID = CBUUID(string: "f000aa05-0451-4000-b000-000000000000")
    
    /* smart contract ID characteristic UUID */
    fileprivate let contractIDUUID: CBUUID = CBUUID(string: "f000aa06-0451-4000-b000-000000000000")
    
    /* characteristic determining the start time of recording */
    fileprivate let startTimeUUID: CBUUID = CBUUID(string: "f000aa07-0451-4000-b000-000000000000")
    
    
    func addCharacteristic(_ characteristic: CBCharacteristic) {
        if isRecognizedCharacteristic(characteristic) {
            characteristics.append(characteristic)
        }
    }
    
//    /* returns sensor battery level, in % */
//    func getSensorBatteryLevel(WithSensorPeripheral peripheral: CBPeripheral) -> Int? {
//        per
//    }
    
    // MARK: Helper functions
    
    fileprivate func isRecognizedCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        switch characteristic.uuid {
            case batteryLevelUUID, isRecordingUUID, measurementsUUID, recordingTimeIntervalUUID, measurementsCountUUID,  measurementsReadIndexUUID, contractIDUUID, startTimeUUID:
                    return true
            default:
                return false
        }
    }
    
    fileprivate func getCharacteristic(ByUUID uuid: CBUUID) -> CBCharacteristic? {
        if let index = characteristics.index(where: {
            characteristic in
            
            return characteristic.uuid == uuid
        }) {
            return characteristics[index]
        } else {
            return nil
        }
    }
    
}
