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
 Singleton class responsible for reccurently uploading TemperatureMeasurementsObject or CreatedParcel objects which failed to upload
 Class also generates user notifications indicating which data failed to upload.
 */
class RecurrentUploader {
    
    // MARK: Properties
    
    static let shared = RecurrentUploader()
    
    // MARK: Constants
    
    private init() {}
    
    /* call this function if there are any pending parcels or measurements to be uploaded upon application start-up */
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
                            
                            let tntNumber = cdParcelToUpload.tntNumber
                            let sensorMAC = cdParcelToUpload.sensorMAC
                            reccurentUploader.uploadParcel(parcel: parcelToUpload, completionHandler: {
                                error, parcel in
                                
                                /* if completed successfully */
                                if parcel != nil, error == nil {
                                    /* remove notification */
                                    UNUserNotificationCenter.current().removeNotification(identifier: "parcel_\(tntNumber)_\(sensorMAC)")
                                    
                                    /* remove object from CoreData */
                                    let parcelFetchRequest = NSFetchRequest<CDCreatedParcel>(entityName: "CDCreatedParcel")
                                    parcelFetchRequest.predicate = NSPredicate(format: "tntNumber == %@ AND sensorMAC == %@", tntNumber, sensorMAC)
                                    backgroundContext.performAndWait({
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
                                    })
                                }
                            })
                        }
                    }
                    let cdTempMeasurementsToUpload = try backgroundContext.fetch(allTempMeasurementsObjectsRequest)
                    for cdTempMeasurementToUpload in cdTempMeasurementsToUpload {
                        if let tempMeasurementsObject = TemperatureMeasurementsObject(WithCoreDataObject: cdTempMeasurementToUpload.measurementsObject) {
                            
                            let tntNumber = cdTempMeasurementToUpload.tntNumber
                            let sensorMAC = cdTempMeasurementToUpload.sensorMAC
                            
                            reccurentUploader.uploadMeasurements(tntNumber: tntNumber, sensorMAC: sensorMAC, measurements: tempMeasurementsObject, completionHandler: {
                                error, measurements in
                                
                                /* if completed successfully */
                                if measurements != nil, error == nil {
                                    /* remove notification */
                                    UNUserNotificationCenter.current().removeNotification(identifier: "measurements_\(tntNumber)_\(sensorMAC)")
                                    
                                    /* remove object from CoreData */
                                    let measurementsFetchRequest = NSFetchRequest<CDTempMeasurementsUpload>(entityName: "CDTempMeasurementsUpload")
                                    measurementsFetchRequest.predicate = NSPredicate(format: "tntNumber == %@ AND sensorMAC == %@", tntNumber, sensorMAC)
                                    backgroundContext.performAndWait({
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
                                    })
                                }
                            })
                        }
                    }
                } catch {
                    log("Failed to fetch objects from CoreData! Error is \(error.localizedDescription)")
                }
            }
        })
    }
    
    /* Adds temperature measurements object for given @tntNumber and @sensorMAC to be uploaded in recurrent fashion:
     - Notification is generated
     - Object is persisted in CoreData
     - New URL session is opened that attempts to upload the object at fixed time intervals
     */
    func addMeasurementsToUpload(tntNumber: String, sensorMAC: String, measurements: TemperatureMeasurementsObject, notifyUser: Bool = true) {
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
                [weak self]
                success in
                
                if let reccurentUploader = self {
                    if success {
                        if notifyUser {
                            /* generate notification */
                            let notificationContent = UNMutableNotificationContent()
                            notificationContent.title = "Pending upload"
                            notificationContent.body = "Temperature measurements for Track&Trace \(tntNumber) failed to upload!"
                            notificationContent.sound = UNNotificationSound.default()
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
                        reccurentUploader.uploadMeasurements(tntNumber: tntNumber, sensorMAC: sensorMAC, measurements: measurements, completionHandler: {
                            error, measurementsObject in
                            
                            /* if completed successfully, just remove notification and the object from CoreData */
                            /* if completed unsucessfully, remove notification and the object from CoreData and generate new notification with cause of error */
                            
                            /* remove notification */
                            UNUserNotificationCenter.current().removeNotification(identifier: "measurements_\(tntNumber)_\(sensorMAC)")
                            
                            /* remove object from CoreData */
                            let measurementsFetchRequest = NSFetchRequest<CDTempMeasurementsUpload>(entityName: "CDTempMeasurementsUpload")
                            measurementsFetchRequest.predicate = NSPredicate(format: "tntNumber == %@ AND sensorMAC == %@", tntNumber, sensorMAC)
                            backgroundContext.performAndWait({
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
                            })
                            
                            if let error = error {
                                switch error {
                                    case ServerError.measurementsForParcelAlreadyExist:
                                        /* generate notification */
                                        let notificationContent = UNMutableNotificationContent()
                                        notificationContent.title = "Failed to upload"
                                        notificationContent.body = "Temperature measurements for parcel with Track&Trace \(tntNumber) already exist!"
                                        notificationContent.sound = UNNotificationSound.default()
                                        let notificationRequest = UNNotificationRequest(identifier: "parcel_\(tntNumber)_\(sensorMAC)", content: notificationContent, trigger: nil)
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
                                    case ServerError.parcelWithTntNotExists:
                                        /* generate notification */
                                        let notificationContent = UNMutableNotificationContent()
                                        notificationContent.title = "Failed to upload"
                                        notificationContent.body = "Parcel with Track&Trace \(tntNumber) doesn't exist!"
                                        notificationContent.sound = UNNotificationSound.default()
                                        let notificationRequest = UNNotificationRequest(identifier: "parcel_\(tntNumber)_\(sensorMAC)", content: notificationContent, trigger: nil)
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
                                    default:
                                        break
                                }
                            }
                        })
                    } else {
                        log("Failed to store temperature measurement upload! Aborting background upload...")
                    }
                }
            })
        })
    }
    
    /* Adds CreatedParcel object to be uploaded in recurrent fashion:
     - Notification is generated
     - Object is persisted in CoreData
     - New URL session is opened that attempts to upload the object at fixed time intervals
     */
    func addParcelToUpload(parcel: CreatedParcel, notifyUser: Bool = true) {
        /* store object in CoreData */
        CoreDataManager.shared.performBackgroundTask(WithBlock: {
            backgroundContext in
            
            let cdCreatedParcel = NSEntityDescription.insertNewObject(forEntityName: "CDCreatedParcel", into: backgroundContext) as! CDCreatedParcel
            parcel.toCoreDataObject(object: cdCreatedParcel)
            
            let tntNumber = cdCreatedParcel.tntNumber
            let sensorMAC = cdCreatedParcel.sensorMAC
            
            CoreDataManager.shared.saveLocally(managedContext: backgroundContext, WithCompletionHandler: {
                [weak self]
                success in

                if let reccurentUploader = self {
                    if success {
                        if notifyUser {
                            /* generate notification */
                            let notificationContent = UNMutableNotificationContent()
                            notificationContent.title = "Pending upload"
                            notificationContent.body = "Parcel for Track&Trace \(tntNumber) failed to upload!"
                            notificationContent.sound = UNNotificationSound.default()
                            let notificationRequest = UNNotificationRequest(identifier: "parcel_\(tntNumber)_\(sensorMAC)", content: notificationContent, trigger: nil)
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
                        
                        reccurentUploader.uploadParcel(parcel: parcel, completionHandler: {
                            error, parcel in
                            
                            /* if completed successfully, just remove notification and the object from CoreData */
                            /* if completed unsucessfully, remove notification and the object from CoreData and generate new notification with cause of error */
                            
                            /* remove notification */
                            UNUserNotificationCenter.current().removeNotification(identifier: "parcel_\(tntNumber)_\(sensorMAC)")
                            
                            /* remove object from CoreData */
                            let parcelFetchRequest = NSFetchRequest<CDCreatedParcel>(entityName: "CDCreatedParcel")
                            parcelFetchRequest.predicate = NSPredicate(format: "tntNumber == %@ AND sensorMAC == %@", tntNumber, sensorMAC)
                            backgroundContext.performAndWait({
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
                            })
                            
                            if let error = error {
                                switch error {
                                    case ServerError.parcelTntAlreadyExists:
                                        /* generate notification */
                                        let notificationContent = UNMutableNotificationContent()
                                        notificationContent.title = "Failed to upload!"
                                        notificationContent.body = "Parcel with Track&Trace \(tntNumber) already exists!"
                                        notificationContent.sound = UNNotificationSound.default()
                                        let notificationRequest = UNNotificationRequest(identifier: "parcel_\(tntNumber)_\(sensorMAC)", content: notificationContent, trigger: nil)
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
                                    case ServerError.parcelMaxFailsIncorrect:
                                        /* generate notification */
                                        let notificationContent = UNMutableNotificationContent()
                                        notificationContent.title = "Failed to upload"
                                        notificationContent.body = "Parcel with Track&Trace \(tntNumber) has incorrect 'maxFailsTemp'!"
                                        notificationContent.sound = UNNotificationSound.default()
                                        let notificationRequest = UNNotificationRequest(identifier: "parcel_\(tntNumber)_\(sensorMAC)", content: notificationContent, trigger: nil)
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
                                    default:
                                        break
                                }
                            
                            }
                        })
                    } else {
                        log("Failed to store created parcel! Aborting background upload...")
                    }
                }
            })
        })
    }
    
    // MARK: Helper methods
    
    fileprivate func uploadParcel(parcel: CreatedParcel, completionHandler: @escaping (ServerError?, Parcel?) -> Void) {
        /* start background upload session */
        ServerManager.shared.createParcel(parcel: parcel, backgroundUpload: true, completionHandler: completionHandler)
    }
    
    fileprivate func uploadMeasurements(tntNumber: String, sensorMAC: String, measurements: TemperatureMeasurementsObject, completionHandler: @escaping (ServerError?, TemperatureMeasurementsObject?) -> Void) {
        /* start background upload session */
        ServerManager.shared.postTemperatureMeasurements(tntNumber: tntNumber, sensorID: sensorMAC, measurements: measurements, backgroundUpload: true, completionHandler: completionHandler)
    }
    
}
