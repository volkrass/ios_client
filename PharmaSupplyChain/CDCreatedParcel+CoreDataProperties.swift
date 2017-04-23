//
//  CDCreatedParcel+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

extension CDCreatedParcel {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCreatedParcel> {
        return NSFetchRequest<CDCreatedParcel>(entityName: "CDCreatedParcel");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var tntNumber: String
    @NSManaged public var sensorMAC: String
    @NSManaged public var maxFailsTemp: Int16
    
    /* relationships */
    @NSManaged public var tempCategory: CDTempCategory
}
