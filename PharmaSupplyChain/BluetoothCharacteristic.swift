//
//  BluetoothCharacteristic.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 10.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol BluetoothCharacteristic {
    
    func getCharacteristicType(FromUUID uuid: CBUUID) -> BluetoothCharacteristic?
    
}
