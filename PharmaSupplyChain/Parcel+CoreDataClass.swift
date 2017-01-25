//
//  Parcel+CoreDataClass.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData
import SwiftyJSON

public class Parcel : NSManagedObject, UniqueManagedObject, JSONSerializable {
    
    // MARK: JSONSerializable
    
    func toJSON() -> JSON? {
        let jsonParcel = JSON([
            "tempCategory": tempCategory,
            "tntNumber" : tntNumber,
            "receiver" : receiver,
            "receiverCompany": receiverCompany,
            "isReceived" : isReceived,
            "sensorID" : sensorMAC,
            "nrFailures" : numFailures,
            "nrMeasurements": numMeasurements,
            "isSent" : isSent,
            "sender" : sender,
            "senderCompany": senderCompany,
            "additionalInfo" : additionalInfo == nil ? "" : additionalInfo!,
            "dateReceived" : dateReceived == nil ? nil : dateReceived!.iso8601
        ])
        return jsonParcel
    }
    
    func fromJSON(object: JSON) {
        if let tempCategory = object["tempCategory"].string {
            self.tempCategory = tempCategory
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
        if let dateReceivedString = object["dateReceived"].string, dateReceivedString != ServerManager.serverNilDateString, let dateReceived = dateReceivedString.dateFromISO8601 {
            self.dateReceived = dateReceived
        }
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "Parcel." + ProcessInfo.processInfo.globallyUniqueString
    }
}
