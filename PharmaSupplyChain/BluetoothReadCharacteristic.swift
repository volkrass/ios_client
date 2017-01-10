//
//  BluetoothReadCharacteristic.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 10.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

protocol BluetoothReadCharacteristic : BluetoothCharacteristic {
    
    func read<T>() -> T?
    
}
