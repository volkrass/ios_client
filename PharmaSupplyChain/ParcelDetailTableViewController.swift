//
//  ParcelDetailTableViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit

class ParcelDetailTableViewController : UITableViewController {
    
    // MARK: CoreData Properties
    
    var parcel: Parcel?
    
    override func viewDidLoad() {
        guard let parcel = parcel else {
            fatalError("ParcelDetailTableViewController.viewDidLoad(): nil instance of Parcel")
        }
    }
    
}
