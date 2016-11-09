//
//  CoreDataEnabledProtocol.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

/* All view controllers that are working with CoreData need to implement this protocol */
protocol CoreDataEnabledController {
    
    var coreDataManager: CoreDataManager? {get set}
    
}
