//
//  SensorConnectViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.12.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit

class SensorConnectViewController : UIViewController, BluetoothDiscoveryDelegate /*, SensorServiceDelegate */ {
    
    // MARK: Properties
    
    fileprivate let bluetoothManager: BluetoothManager = BluetoothManager.shared
    
    // MARK: Constants
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.bluetoothDiscoveryDelegate = self
        //bluetoothManager.sensorServiceDelegate = self
    }
    
    // MARK: BluetoothDiscoveryDelegate
    
    func bluetoothErrorOccurred() {
        
    }
    
    func sensorDiscovered() {
        
    }
    
    // MARK: SensorServiceDelegate

    
}
