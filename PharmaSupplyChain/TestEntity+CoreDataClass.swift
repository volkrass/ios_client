//
//  TestRecord+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

/* CoreData class that is used for testing purposes */
class TestEntity: NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "TestEntity." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
