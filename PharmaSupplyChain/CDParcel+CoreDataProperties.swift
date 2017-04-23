//
//  Parcel+CoreDataProperties.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

extension CDParcel {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDParcel> {
        return NSFetchRequest<CDParcel>(entityName: "CDParcel");
    }
    
    /* Metadata properties */
    @NSManaged public var identifier: String
    
    @NSManaged public var id: Int
    @NSManaged public var senderCompany: String
    @NSManaged public var receiverCompany: String
    @NSManaged public var dateSent: Date
    @NSManaged public var dateReceived: Date?
    @NSManaged public var isSent: Bool
    @NSManaged public var isReceived: Bool
    @NSManaged public var isFailed: Bool
    @NSManaged public var isSuccess: Bool
    @NSManaged public var sensorID: String?
    @NSManaged public var tempCategory: String
    @NSManaged public var minTemp: Int
    @NSManaged public var maxTemp: Int
    @NSManaged public var tntNumber: String
    @NSManaged public var additionalInfo: String?
    @NSManaged public var localInterpretationSuccess: Bool
    
}
