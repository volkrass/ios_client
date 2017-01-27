//
//  Parcel+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData
import SwiftyJSON

enum ParcelStatus : String {
    case inProgress = "In Progress"
    case notWithinTemperatureRange = "Failed to stay within temperature range"
    case successful = "Successful"
    case undetermined = "Undetermined"
}

public class Parcel : NSManagedObject, UniqueManagedObject, JSONSerializable {
    
    // MARK: JSONSerializable
    
    func toJSON() -> JSON? {
        let jsonParcel = JSON([
            "id" : id,
            "tempCategory" : tempCategory,
            "minTemp" : minTemp,
            "maxTemp" : maxTemp,
            "tntNumber" : tntNumber,
            "receiver" : receiver,
            "receiverCompany": receiverCompany,
            "isSuccess" : isSuccess,
            "isFailed" : isFailed,
            "isSent" : isSent,
            "isReceived" : isReceived,
            "sensorID" : sensorMAC,
            "nrFailures" : numFailures,
            "nrMeasurements": numMeasurements,
            "sender" : sender,
            "senderCompany": senderCompany,
            "additionalInfo" : additionalInfo == nil ? "" : additionalInfo!,
            "dateReceived" : dateReceived == nil ? nil : dateReceived!.iso8601,
            "dateSent" : dateSent
        ])
        return jsonParcel
    }
    
    func fromJSON(object: JSON) {
        if let id = object["id"].int {
            self.id = id
        }
        if let tempCategory = object["tempCategory"].string {
            self.tempCategory = tempCategory
        }
        if let minTemp = object["minTemp"].int {
            self.minTemp = minTemp
        }
        if let maxTemp = object["maxTemp"].int {
            self.maxTemp = maxTemp
        }
        if let tntNumber = object["tntNumber"].string {
            self.tntNumber = tntNumber
        }
        if let receiver = object["receiver"].string {
            self.receiver = receiver
        }
        if let receiverCompany = object["receiverCompany"].string {
            self.receiverCompany = receiverCompany
        }
        if let isReceived = object["isReceived"].bool {
            self.isReceived = isReceived
        }
        if let isSuccess = object["isSuccess"].bool {
            self.isSuccess = isSuccess
        }
        if let isFailed = object["isFailed"].bool {
            self.isFailed = isFailed
        }
        if let sensorMAC = object["sensorID"].string {
            self.sensorMAC = sensorMAC
        }
        if let numFailures = object["nrFailures"].int {
            self.numFailures = numFailures
        }
        if let numMeasurements = object["nrMeasurements"].int {
            self.numMeasurements = numMeasurements
        }
        if let isSent = object["isSent"].bool {
            self.isSent = isSent
        }
        if let sender = object["sender"].string {
            self.sender = sender
        }
        if let senderCompany = object["senderCompany"].string {
            self.senderCompany = senderCompany
        }
        if let additionalInfo = object["additionalInfo"].string {
            self.additionalInfo = additionalInfo
        }
        if let dateSentString = object["dateSent"].string, dateSentString != ServerManager.serverNilDateString, let dateSent = dateSentString.dateFromISO8601 {
            self.dateSent = dateSent
        }
        if let dateReceivedString = object["dateReceived"].string, dateReceivedString != ServerManager.serverNilDateString, let dateReceived = dateReceivedString.dateFromISO8601 {
            self.dateReceived = dateReceived
        }
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "Parcel." + ProcessInfo.processInfo.globallyUniqueString
    }
    
    func getStatus() -> ParcelStatus {
        if isSuccess && isFailed {
            return .undetermined
        } else if isSuccess && !isFailed {
            return .successful
        } else if !isSuccess && isFailed {
            return .notWithinTemperatureRange
        } else {
            return .inProgress
        }
    }
}
