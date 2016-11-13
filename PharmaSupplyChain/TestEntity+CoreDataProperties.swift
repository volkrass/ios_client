//
//  TestRecord+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

extension TestEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestEntity> {
        return NSFetchRequest<TestEntity>(entityName: "TestEntity");
    }
    
    // MARK: UniqueManagedObject
    @NSManaged public var identifier: String
    
    @NSManaged public var createdAt: Date
    @NSManaged public var name: String
    @NSManaged public var optional: String?
    
}
