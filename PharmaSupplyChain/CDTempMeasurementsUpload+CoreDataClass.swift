//
//  CDTempMeasurementsUpload+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

/* CoreData class that stores necessary data for POST http://dev.modum.io/api/parcels/<tntNumber>/<sensorID>/temperatures call in case it failed and has to be retried */
public class CDTempMeasurementsUpload : NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDTempMeasurementsUpload." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
