//
//  CDTempMeasurement+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

extension CDTempMeasurement {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTempMeasurement> {
        return NSFetchRequest<CDTempMeasurement>(entityName: "CDTempMeasurement");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var timestamp: Date
    @NSManaged public var temperature: Double
    
    @NSManaged public var measurementsObject: CDTempMeasurementsObject?
    
}
