//
//  CreatedParcel.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 26.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper
import CoreData

class CreatedParcel : Mappable, CoreDataObject {
    
    // MARK: Properties
    
    var tntNumber: String?
    var sensorUUID: String?
    var tempCategory: TemperatureCategory?
    var maxFailsTemp: Int?
    
    public init() {}
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        tntNumber <- map["tntNumber"]
        sensorUUID <- map["sensorUUID"]
        tempCategory <- map["tempCategory"]
        maxFailsTemp <- map["maxFailsTemp"]
    }
    
    // MARK: CoreDataObject
    
    public required init?(WithCoreDataObject object: CDCreatedParcel) {
        tntNumber = object.tntNumber
        sensorUUID = object.sensorMAC
        maxFailsTemp = object.maxFailsTemp
        tempCategory = TemperatureCategory(WithCoreDataObject: object.tempCategory)
    }

    public func toCoreDataObject(object: CDCreatedParcel) {
        if let tempCategory = tempCategory, let sensorUUID = sensorUUID, let tntNumber = tntNumber, let maxFailsTemp = maxFailsTemp {
            if let moc = object.managedObjectContext, let cdTempCategory = NSEntityDescription.insertNewObject(forEntityName: "CDTempCategory", into: moc) as? CDTempCategory {
                tempCategory.toCoreDataObject(object: cdTempCategory)
                object.tempCategory = cdTempCategory
            }
            object.sensorMAC = sensorUUID
            object.maxFailsTemp = maxFailsTemp
            object.tntNumber = tntNumber
        }
    }
    
}
