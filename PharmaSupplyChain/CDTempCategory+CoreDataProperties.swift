//
//  CDTempCategory+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

extension CDTempCategory {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTempCategory> {
        return NSFetchRequest<CDTempCategory>(entityName: "CDTempCategory");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var name: String
    @NSManaged public var label: String?
    @NSManaged public var minTemp: Int
    @NSManaged public var maxTemp: Int
    
    /* relationships */
    @NSManaged public var companyDefaultsForDefaultTemp: CDCompanyDefaults?
    @NSManaged public var companyDefaultsForDefaultCategories: CDCompanyDefaults?
    @NSManaged public var createdParcels: NSSet?
    
}

extension CDTempCategory {
    
    @objc(addCreatedParcelsObject:)
    @NSManaged public func addToCreatedParcels(_ value: CDTempCategory)
    
    @objc(removeCreatedParcelsObject:)
    @NSManaged public func removeFromCreatedParcels(_ value: CDTempCategory)
    
    @objc(addCreatedParcels:)
    @NSManaged public func addToCreatedParcels(_ values: NSSet)
    
    @objc(removeCreatedParcels:)
    @NSManaged public func removeFromCreatedParcels(_ values: NSSet)
}
