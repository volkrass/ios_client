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
    
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var dateReceived: Date?
    @NSManaged public var dateSent: Date?
    @NSManaged public var contractAddress: String
    @NSManaged public var tntNumber: String
    @NSManaged public var parcelId: Int
    @NSManaged public var senderId: Int
    @NSManaged public var receiverId: Int
    @NSManaged public var sensorUUID: String
    @NSManaged public var txHash: String
    @NSManaged public var maxFailsTemp: Int
    @NSManaged public var contractVersion: Int
    @NSManaged public var additionalInfo: String?
    @NSManaged public var isReceived: Bool
    @NSManaged public var isSent: Bool
    
}
