//
//  Parcel.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 24.02.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

enum ParcelStatus : String {
    case inProgress = "In Progress"
    case notWithinTemperatureRange = "Failed"
    case successful = "Successful"
    case undetermined = "Undetermined"
    
    static func getStatus(isSuccess: Bool, isFailure: Bool, isReceived: Bool, localInterpretationStatus: Bool) -> ParcelStatus {
        if !isReceived {
            return .inProgress
        } else if isSuccess && !isFailure {
            return .successful
        } else if !isSuccess && isFailure {
            return .notWithinTemperatureRange
        } else if localInterpretationStatus {
            return .successful
        } else {
            return .undetermined
        }
    }
}

class Parcel : Mappable, CoreDataObject {
    
    // MARK: Properties
    
    var id: Int?
    var tntNumber: String?
    var senderCompany: String?
    var receiverCompany: String?
    var sensorID: String?
    var isSuccess: Bool?
    var isFailure: Bool?
    var isSent: Bool?
    var isReceived: Bool?
    var dateSent: Date?
    var dateReceived: Date?
    var additionalInfo: String?
    var localInterpretationSuccess: Bool?
    
    /* On server-side should be replaced by TemperatureCategory object */
    var minTemp: Int?
    var maxTemp: Int?
    var temperatureCategory: String?
    
    var parcelStatus: ParcelStatus?
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        id <- map["id"]
        temperatureCategory <- map["tempCategory"]
        minTemp <- map["minTemp"]
        maxTemp <- map["maxTemp"]
        tntNumber <- map["tntNumber"]
        senderCompany <- map["senderCompany"]
        receiverCompany <- map["receiverCompany"]
        sensorID <- map["sensorID"]
        isReceived <- map["isReceived"]
        isSent <- map["isSent"]
        isSuccess <- map["isSuccess"]
        isFailure <- map["isFailed"]
        dateSent <- (map["dateSent"], ServerDateTransform())
        dateReceived <- (map["dateReceived"], ServerDateTransform())
        additionalInfo <- map["additionalInfo"]
        localInterpretationSuccess <- map["localInterpretationSuccess"]
        /* determining status */
        if let isSuccess = isSuccess, let isFailure = isFailure, let isReceived = isReceived, let localInterpretationSuccess = localInterpretationSuccess {
            parcelStatus = ParcelStatus.getStatus(isSuccess: isSuccess, isFailure: isFailure, isReceived:  isReceived, localInterpretationStatus: localInterpretationSuccess)
        }
    }
    
    // MARK: CoreDataObject
    
    required public init?(WithCoreDataObject object: CDParcel) {
        id = object.id
        temperatureCategory = object.tempCategory
        minTemp = object.minTemp
        maxTemp = object.maxTemp
        tntNumber = object.tntNumber
        senderCompany = object.senderCompany
        receiverCompany = object.receiverCompany
        isReceived = object.isReceived
        isSent = object.isSent
        isSuccess = object.isSuccess
        isFailure = object.isFailed
        dateSent = object.dateSent
        dateReceived = object.dateReceived
        additionalInfo = object.additionalInfo
        localInterpretationSuccess = object.localInterpretationSuccess
    }
    
    public func toCoreDataObject(object: CDParcel) {
        if let id = id, let temperatureCategory = temperatureCategory, let minTemp = minTemp, let maxTemp = maxTemp, let tntNumber = tntNumber, let senderCompany = senderCompany, let receiverCompany = receiverCompany, let isReceived = isReceived, let isSent = isSent, let isFailure = isFailure, let isSuccess = isSuccess, let dateSent = dateSent {
            object.id = id
            object.tempCategory = temperatureCategory
            object.minTemp = minTemp
            object.maxTemp = maxTemp
            object.tntNumber = tntNumber
            object.senderCompany = senderCompany
            object.receiverCompany = receiverCompany
            object.isReceived = isReceived
            object.isSent = isSent
            object.isFailed = isFailure
            object.isSuccess = isSuccess
            object.dateSent = dateSent
            object.dateReceived = dateReceived
            object.additionalInfo = additionalInfo
        }
    }
    
}
