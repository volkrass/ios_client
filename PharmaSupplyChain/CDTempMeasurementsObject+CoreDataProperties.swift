//
//  CDTempMeasurementsObject+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

extension CDTempMeasurementsObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTempMeasurementsObject> {
        return NSFetchRequest<CDTempMeasurementsObject>(entityName: "CDTempMeasurementsObject");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var localInterpretationSuccess: Bool
    
    @NSManaged public var measurements: [CDTempMeasurement]
    @NSManaged public var uploadObject: CDTempMeasurementsUpload?
}
