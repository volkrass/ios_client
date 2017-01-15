//
//  BluetoothService.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreBluetooth

protocol BluetoothService {

    static var uuid: CBUUID { get }
    
    func start()
    
}
