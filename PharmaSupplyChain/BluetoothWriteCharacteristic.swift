//
//  BluetoothWriteCharacteristic.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 10.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

protocol BluetoothWriteCharacteristic : BluetoothCharacteristic {
    
    func write<T>(_ value: T)
    
}

