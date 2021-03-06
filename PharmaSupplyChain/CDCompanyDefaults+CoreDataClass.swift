//
//  CDCompanyDefaults+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

/* CoreData class dedicated to store CompanyDefaults model object */
public class CDCompanyDefaults : NSManagedObject, UniqueManagedObject {

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDCompanyDefaults." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
