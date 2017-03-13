//
//  CDTempCategory+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import CoreData

public class CDTempCategory : NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDTempCategory." + ProcessInfo.processInfo.globallyUniqueString
    }
    
}
