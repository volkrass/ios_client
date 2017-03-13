//
//  Parcel+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

public class CDParcel : NSManagedObject, UniqueManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "CDParcel." + ProcessInfo.processInfo.globallyUniqueString
    }

}
