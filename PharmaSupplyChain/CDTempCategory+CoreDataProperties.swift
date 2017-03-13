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
    
}
