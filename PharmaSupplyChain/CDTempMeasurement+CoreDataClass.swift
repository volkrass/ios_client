//
//  CDTempMeasurement+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

/* CoreData class dedicated to store TemperatureMeasurement model object */
public class CDTempMeasurement : NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDTempMeasurement." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
