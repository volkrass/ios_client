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
    
    @NSManaged public var measurements: NSSet
    @NSManaged public var uploadObject: CDTempMeasurementsUpload?
}

extension CDTempMeasurementsObject {
    
    @objc(addMeasurementsObject:)
    @NSManaged public func addToMeasurements(_ value: CDTempMeasurement)
    
    @objc(removeMeasurementsObject:)
    @NSManaged public func removeFromMeasurements(_ value: CDTempMeasurement)
    
    @objc(addMeasurements:)
    @NSManaged public func addToMeasurements(_ values: NSSet)
    
    @objc(removeMeasurements:)
    @NSManaged public func removeFromMeasurements(_ values: NSSet)
}
