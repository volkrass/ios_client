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
                                "contractAddress" : contractAddress,
                                "tntNumber" : tntNumber,
                                "CreatedAt" : createdAt == nil ? nil : ServerUtils.serverDateString(FromDate: createdAt!),
                                "ID" : parcelId,
                                "receiver" : receiverId,
                                "UpdatedAt" : updatedAt == nil ? nil : ServerUtils.serverDateString(FromDate: updatedAt!),
                                "isReceived" : isReceived,
                                "sensorUUID" : sensorUUID,
                                "txHash" : txHash,
                                "maxFailsTemp" : maxFailsTemp,
                                "isSent" : isSent,
                                "contractVersion" : contractVersion,
                                "dateSent" : dateSent == nil ? "" : ServerUtils.serverDateString(FromDate: dateSent!),
                                "sender" : senderId,
                                "addInfo" : additionalInfo == nil ? "" : additionalInfo!,
                                "dateReceived" : dateReceived == nil ? "" : ServerUtils.serverDateString(FromDate: dateReceived!)
                             ])
        return jsonParcel
    }
    
    func fromJSON(object: JSON) {
        if let contractAddress = object["contractAddress"].string {
            self.contractAddress = contractAddress
        }
        if let tntNumber = object["tntNumber"].string {
            self.tntNumber = tntNumber
        }
        if let createdAtString = object["CreatedAt"].string, let createdAt = ServerUtils.date(FromServerString: createdAtString) {
            self.createdAt = createdAt
        }
        if let parcelId = object["ID"].int {
            self.parcelId = parcelId
        }
        if let receiverId = object["receiver"].int {
            self.receiverId = receiverId
        }
        if let updatedAtString = object["UpdatedAt"].string, let updatedAt = ServerUtils.date(FromServerString: updatedAtString) {
            self.updatedAt = updatedAt
        }
        if let isReceived = object["isReceived"].bool {
            self.isReceived = isReceived
        }
        if let sensorUUID = object["sensorUUID"].string {
            self.sensorUUID = sensorUUID
        }
        if let txHash = object["txHash"].string {
            self.txHash = txHash
        }
        if let maxFailsTemp = object["maxFailsTemp"].int {
            self.maxFailsTemp = maxFailsTemp
        }
        if let isSent = object["isSent"].bool {
            self.isSent = isSent
        }
        if let contractVersion = object["contractVersion"].int {
            self.contractVersion = contractVersion
        }
        if let dateSentString = object["dateSent"].string, let dateSent = ServerUtils.date(FromServerString: dateSentString) {
            self.dateSent = dateSent
        }
        if let senderId = object["sender"].int {
            self.senderId = senderId
        }
        if let additionalInfo = object["addInfo"].string {
            self.additionalInfo = additionalInfo
        }
        if let dateReceivedString = object["dateReceived"].string, let dateReceived = ServerUtils.date(FromServerString: dateReceivedString) {
            self.dateReceived = dateReceived
        }
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        identifier = "Parcel." + ProcessInfo.processInfo.globallyUniqueString
    }
}
