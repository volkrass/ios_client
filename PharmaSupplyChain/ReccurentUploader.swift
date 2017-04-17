//
//  ReccurentUploader.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Alamofire
import CoreData

/* 
 Singleton class responsible for reccurently uploading data which failed to upload
 TemperatureMeasurementsObject or CreatedParcel objects that have failed to upload are stored in CoreData. Once they are uploaded, they are removed, thus, only those objects are stored in CoreData that should be uploaded.
 */
class RecurrentUploader {
    
    // MARK: Properties
    
    static let shared = RecurrentUploader()
    
    // MARK: Constants
    
    private init() {}
    
    func resumeDownloads() {
        let allCreatedParcelsRequest = NSFetchRequest<CDCreatedParcel>(entityName: "CDCreatedParcel")
        allCreatedParcelsRequest.predicate = NSPredicate(value: true)
        let allTempMeasurementsObjectsRequest = NSFetchRequest<CDTempMeasurementsUpload>(entityName: "CDTempMeasurementsUpload")
        allTempMeasurementsObjectsRequest.predicate = NSPredicate(value: true)
        CoreDataManager.shared.performBackgroundTask(WithBlock: {
            backgroundMoc in
            
            do {
                let cdParcelsToUpload = try backgroundMoc.fetch(allCreatedParcelsRequest)
                for cdParcelToUpload in cdParcelsToUpload {
                    if let parcelToUpload = CreatedParcel(WithCoreDataObject: cdParcelToUpload) {
                        ServerManager.shared.createParcel(parcel: parcelToUpload, completionHandler: {
                            error, response in
                            /* TODO remove parcel from CoreData and remove notification */
                        })
                    }
                }
                let cdTempMeasurementsToUpload = try backgroundMoc.fetch(allTempMeasurementsObjectsRequest)
                for cdTempMeasurementToUpload in cdTempMeasurementsToUpload {
                    if let tempMeasurementsObject = TemperatureMeasurementsObject(WithCoreDataObject: cdTempMeasurementToUpload.measurementsObject) {
                            ServerManager.shared.postTemperatureMeasurements(tntNumber: cdTempMeasurementToUpload.tntNumber, sensorID: cdTempMeasurementToUpload.sensorMAC, measurements: tempMeasurementsObject, completionHandler: {
                                error, response in
                                
                                /* TODO remove temp Measuremetns from CoreData and remove notification */
                            })
                    }
                }
            } catch {
                log("Failed to fetch objects from CoreData! Error is \(error.localizedDescription)")
            }
        })
    }
    
    func addMeasurementsToUpload(tntNumber: String, sensorMAC: String, measurements: [TemperatureMeasurement]) {
        
    }
    
    func addParcelToUpload(parcel: CreatedParcel) {
        
    }
    
}
