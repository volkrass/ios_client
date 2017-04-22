//
//  ReccurentUploader.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Alamofire
import CoreData
import UserNotifications

/* 
 Singleton class responsible for reccurently uploading data which failed to upload
 TemperatureMeasurementsObject or CreatedParcel objects that have failed to upload are stored in CoreData. Once they are uploaded, they are removed, thus, only those objects are stored in CoreData that should be uploaded.
 */
class RecurrentUploader {
    
    // MARK: Properties
    
    static let shared = RecurrentUploader()
    
    fileprivate var createdParcels: [CreatedParcel] = []
    fileprivate var measurementsToUpload: [(tntNumber: String, sensorID: String, measurements: TemperatureMeasurementsObject)] = []
    
    // MARK: Constants
    
    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {
            success, error in
            
            if !success {
                log("Notifications are disabled for the application")
            }
            if let error = error {
                log("Error requesting permission to send notifications: \(error.localizedDescription)")
            }
        })
    }
    
    func resumeDownloads() {
        let allCreatedParcelsRequest = NSFetchRequest<CDCreatedParcel>(entityName: "CDCreatedParcel")
        allCreatedParcelsRequest.predicate = NSPredicate(value: true)
        let allTempMeasurementsObjectsRequest = NSFetchRequest<CDTempMeasurementsUpload>(entityName: "CDTempMeasurementsUpload")
        allTempMeasurementsObjectsRequest.predicate = NSPredicate(value: true)
        CoreDataManager.shared.performBackgroundTask(WithBlock: {
            [weak self]
            backgroundContext in
            
            if let reccurentUploader = self {
                do {
                    let cdParcelsToUpload = try backgroundContext.fetch(allCreatedParcelsRequest)
                    for cdParcelToUpload in cdParcelsToUpload {
                        if let parcelToUpload = CreatedParcel(WithCoreDataObject: cdParcelToUpload) {
                            reccurentUploader.addParcelToUpload(parcel: parcelToUpload, notifyUser: false)
                        }
                    }
                    let cdTempMeasurementsToUpload = try backgroundContext.fetch(allTempMeasurementsObjectsRequest)
                    for cdTempMeasurementToUpload in cdTempMeasurementsToUpload {
                        if let tempMeasurementsObject = TemperatureMeasurementsObject(WithCoreDataObject: cdTempMeasurementToUpload.measurementsObject) {
                            reccurentUploader.addMeasurementsToUpload(tntNumber: cdTempMeasurementToUpload.tntNumber, sensorMAC: cdTempMeasurementToUpload.sensorMAC, measurements: tempMeasurementsObject, notifyUser: false)
                        }
                    }
                } catch {
                    log("Failed to fetch objects from CoreData! Error is \(error.localizedDescription)")
                }
            }
        })
    }
    
    func addMeasurementsToUpload(tntNumber: String, sensorMAC: String, measurements: TemperatureMeasurementsObject, notifyUser: Bool = true) {
        measurementsToUpload.append((tntNumber: tntNumber, sensorID: sensorMAC, measurements: measurements))
        
        /* store object in CoreData */
        CoreDataManager.shared.performBackgroundTask(WithBlock: {
            backgroundContext in
            
            let cdMeasurementsToUpload = NSEntityDescription.insertNewObject(forEntityName: "CDTempMeasurementsUpload", into: backgroundContext) as! CDTempMeasurementsUpload
            cdMeasurementsToUpload.tntNumber = tntNumber
            cdMeasurementsToUpload.sensorMAC = sensorMAC
            
            let cdMeasurementsObject = NSEntityDescription.insertNewObject(forEntityName: "CDTempMeasurementsObject", into: backgroundContext) as! CDTempMeasurementsObject
            measurements.toCoreDataObject(object: cdMeasurementsObject)
            
            cdMeasurementsToUpload.measurementsObject = cdMeasurementsObject
            
            CoreDataManager.shared.saveLocally(managedContext: backgroundContext, WithCompletionHandler: {
                success in
                
                if success {
                    if notifyUser {
                        /* generate notification */
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.body = "Temperature measurements for parcel with \(tntNumber) failed to upload"
                        let notificationRequest = UNNotificationRequest(identifier: "measurements_\(tntNumber)_\(sensorMAC)", content: notificationContent, trigger: nil)
                        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {
                            settings in
                            
                            if settings.authorizationStatus == .authorized {
                                UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: {
                                    error in
                                    
                                    if let error = error {
                                        log("Failed to add notification: \(error.localizedDescription)")
                                    }
                                })
                            } else {
                                log("No permission to add notifications! Aborting...")
                            }
                        })
                    }
                    
                    /* start background upload session */
                    ServerManager.shared.postTemperatureMeasurements(tntNumber: tntNumber, sensorID: sensorMAC, measurements: measurements, backgroundUpload: true, completionHandler: {
                        [weak self]
                        error, measurementsObject in
                        
                        if measurementsObject != nil, error == nil {
                            /* remove notification */
                            UNUserNotificationCenter.current().removeNotification(identifier: "measurements_\(tntNumber)_\(sensorMAC)")
                            
                            /* remove object from CoreData */
                            let measurementsFetchRequest = NSFetchRequest<CDTempMeasurementsUpload>(entityName: "CDTempMeasurementsUpload")
                            measurementsFetchRequest.predicate = NSPredicate(format: "tntNumber == %@ AND sensorMAC == %@", tntNumber, sensorMAC)
                            do {
                                let results = try backgroundContext.fetch(measurementsFetchRequest)
                                if results.count > 1 {
                                    log("Objects with duplicated tntNumber and sensorMAC are found!")
                                }
                                for result in results {
                                    backgroundContext.delete(result)
                                }
                                CoreDataManager.shared.saveLocally(managedContext: backgroundContext, WithCompletionHandler: {
                                    success in
                                    
                                    if !success {
                                        log("Failed to delete temperature measurement upload from CoreData!")
                                    }
                                })
                            } catch {
                                log("Failed to execute fetch request! Error is \(error.localizedDescription)")
                            }
                            
                            if let reccurentUploader = self {
                                if let index = reccurentUploader.measurementsToUpload.index(where: {
                                    object in
                                    
                                    return object.tntNumber == tntNumber && object.sensorID == sensorMAC
                                }) {
                                    reccurentUploader.measurementsToUpload.remove(at: index)
                                }
                            }
                        }
                    })
                } else {
                    log("Failed to store temperature measurement upload! Aborting background upload...")
                }
            })
        })
    }
    
    func addParcelToUpload(parcel: CreatedParcel, notifyUser: Bool = true) {
        createdParcels.append(parcel)
        
        /* store object in CoreData */
        CoreDataManager.shared.performBackgroundTask(WithBlock: {
            backgroundContext in
            
            let cdCreatedParcel = NSEntityDescription.insertNewObject(forEntityName: "CDCreatedParcel", into: backgroundContext) as! CDCreatedParcel
            parcel.toCoreDataObject(object: cdCreatedParcel)
            
            CoreDataManager.shared.saveLocally(managedContext: backgroundContext, WithCompletionHandler: {
                success in
                
                if success {
                    if notifyUser {
                        /* generate notification */
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.body = "Created parcel with \(cdCreatedParcel.tntNumber) failed to upload"
                        let notificationRequest = UNNotificationRequest(identifier: "parcel_\(cdCreatedParcel.tntNumber)_\(cdCreatedParcel.sensorMAC)", content: notificationContent, trigger: nil)
                        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {
                            settings in
                            
                            if settings.authorizationStatus == .authorized {
                                UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: {
                                    error in
                                    
                                    if let error = error {
                                        log("Failed to add notification: \(error.localizedDescription)")
                                    }
                                })
                            } else {
                                log("No permission to add notifications! Aborting...")
                            }
                        })
                    }
                    
                    /* start background upload session */
                    ServerManager.shared.createParcel(parcel: parcel, backgroundUpload: true, completionHandler: {
                        [weak self]
                        error, parcel in
                        
                        if parcel != nil, error == nil {
                            /* remove notification */
                            UNUserNotificationCenter.current().removeNotification(identifier: "parcel_\(cdCreatedParcel.tntNumber)_\(cdCreatedParcel.sensorMAC)")
                            
                            /* remove object from CoreData */
                            let parcelFetchRequest = NSFetchRequest<CDCreatedParcel>(entityName: "CDCreatedParcel")
                            parcelFetchRequest.predicate = NSPredicate(format: "tntNumber == %@ AND sensorMAC == %@", cdCreatedParcel.tntNumber, cdCreatedParcel.sensorMAC)
                            do {
                                let results = try backgroundContext.fetch(parcelFetchRequest)
                                if results.count > 1 {
                                    log("Objects with duplicated tntNumber and sensorMAC are found!")
                                }
                                for result in results {
                                    backgroundContext.delete(result)
                                }
                                CoreDataManager.shared.saveLocally(managedContext: backgroundContext, WithCompletionHandler: {
                                    success in
                                    
                                    if !success {
                                        log("Failed to delete parcel object from CoreData!")
                                    }
                                })
                            } catch {
                                log("Failed to execute fetch request! Error is \(error.localizedDescription)")
                            }
                            
                            if let reccurentUploader = self {
                                if let index = reccurentUploader.createdParcels.index(where: {
                                    object in
                                    
                                    if object.tntNumber != nil, object.sensorUUID != nil {
                                        return object.tntNumber! == cdCreatedParcel.tntNumber && object.sensorUUID! == cdCreatedParcel.sensorMAC
                                    } else {
                                        return false
                                    }
                                }) {
                                    reccurentUploader.createdParcels.remove(at: index)
                                }
                            }
                        }
                    })
                } else {
                    log("Failed to store created parcel! Aborting background upload...")
                }
            })
        })
    }
    
}
