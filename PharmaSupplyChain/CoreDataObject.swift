//
//  CoreDataObject.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 24.02.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

/* All model objects that allow to be stored to or read from CoreData should conform to this protocol */
protocol CoreDataObject {
    
    associatedtype T : UniqueManagedObject
    
    init?(WithCoreDataObject object: T)
    
    func toCoreDataObject(object: T)
    
}
