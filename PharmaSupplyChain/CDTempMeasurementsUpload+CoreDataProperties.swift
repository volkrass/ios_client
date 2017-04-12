//
//  CDTempMeasurementsUpload+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

extension CDTempMeasurementsUpload {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTempMeasurementsUpload> {
        return NSFetchRequest<CDTempMeasurementsUpload>(entityName: "CDTempMeasurementsUpload");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var tntNumber: String
    @NSManaged public var sensorMAC: String
    
    @NSManaged public var measurementsObject: CDTempMeasurementsObject
}
