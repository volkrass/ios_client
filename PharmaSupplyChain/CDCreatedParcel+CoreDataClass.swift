//
//  CDCreatedParcel+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

/* CoreData class dedicated to store CreatedParcel model object */
public class CDCreatedParcel : NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDCreatedParcel." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
