//
//  CDTempMeasurementsObject+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

/* CoreData class dedicated to store TemperatureMeasurementsObject model object */
public class CDTempMeasurementsObject : NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDTempMeasurementsObject." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
