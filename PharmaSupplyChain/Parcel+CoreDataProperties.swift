//
//  Parcel+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

extension Parcel {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Parcel> {
        return NSFetchRequest<Parcel>(entityName: "Parcel");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var numFailures: Int
    @NSManaged public var numMeasurements: Int
    @NSManaged public var senderCompany: String
    @NSManaged public var sender: String
    @NSManaged public var receiverCompany: String
    @NSManaged public var receiver: String
    @NSManaged public var dateReceived: Date?
    @NSManaged public var isSent: Bool
    @NSManaged public var isReceived: Bool
    @NSManaged public var sensorMAC: String
    @NSManaged public var tempCategory: String
    @NSManaged public var tntNumber: String
    @NSManaged public var additionalInfo: String?
    
}
