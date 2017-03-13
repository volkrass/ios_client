//
//  CDCompanyDefaults+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

extension CDCompanyDefaults {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCompanyDefaults> {
        return NSFetchRequest<CDCompanyDefaults>(entityName: "CDCompanyDefaults");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var defaultMeasurementInterval: Int
    
    /* relationships */
    @NSManaged public var defaultTempCategory: CDTempCategory
    @NSManaged public var tempCategories: NSSet
    
}

extension CDCompanyDefaults {
    
    @objc(addTempCategoriesObject:)
    @NSManaged public func addToTempCategories(_ value: CDTempCategory)
    
    @objc(removeTempCategoriesObject:)
    @NSManaged public func removeFromTempCategories(_ value: CDTempCategory)
    
    @objc(addTempCategories:)
    @NSManaged public func addToTempCategories(_ values: NSSet)
    
    @objc(removeTempCategories:)
    @NSManaged public func removeFromTempCategories(_ values: NSSet)
}
