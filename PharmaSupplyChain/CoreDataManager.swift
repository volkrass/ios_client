//
//  CoreDataManager.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 2.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

/*
 
 The structure of CoreData access is as follows:
 CoreData Persistent Storage
 ^          ^
 |          |__________
 |                     |
 Private Writer Context     Main Object Context
 ^                     (READ)
 |
 |
 ^
 ------------|--------------
 |            |              |
 Background 1  Background 2 ... Background N
 (WRITE)
 
 */
class CoreDataManager {
    
    static let shared: CoreDataManager = CoreDataManager()
    
    // MARK - Constants
    
    fileprivate let persistentStoreOptions: [String : Bool] = [
        NSMigratePersistentStoresAutomaticallyOption: true,
        NSInferMappingModelAutomaticallyOption: true
    ]
    
    // MARK - Properties
    
    static var storeURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[0]
        /* "PharmaSupplyChainDataModel.sqlite" is stored in the application's documents directory. */
        let storeURL = docURL.appendingPathComponent("PharmaSupplyChainDataModel.sqlite")
        return storeURL
    }
    
    /* NSManagedObjectContext for background, long-lived operations */
    private var privateWriterContext: NSManagedObjectContext
    /* NSManagedObjectContext for UI-related operations */
    var viewingContext: NSManagedObjectContext
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    /* private initializer for singleton class */
    private init() {
        /* Generates URL to the data model */
        guard let modelURL = Bundle.main.url(forResource: "PharmaSupplyChainDataModel", withExtension:"momd") else {
            fatalError("Error loading data model for Core Data from bundle")
        }
        guard let dataModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing data model from: \(modelURL)")
        }
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: dataModel)
        
        privateWriterContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateWriterContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        /* To be used for reading only */
        viewingContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        viewingContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: CoreDataManager.storeURL, options: persistentStoreOptions)
        } catch {
            fatalError("CoreDataManager.init: error migrating persistent data store: \(error.localizedDescription)")
        }
    }
    
    /* Performs given block in background NSManagedObjectContext */
    func performBackgroundTask(WithBlock block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = createBackgroundContext()
        backgroundContext.performAndWait({
            block(backgroundContext)
        })
    }
    
    /* Returns NSManagedObjectContext for background-related tasks */
    fileprivate func createBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = privateWriterContext
        return backgroundContext
    }
    
    /* Saves given NSManagedContext changes to NSPersistentStore providing optional completionHandler */
    func saveLocally(managedContext: NSManagedObjectContext, WithCompletionHandler completionHandler: ((_ success: Bool) -> Void)? = nil) {
        /* saves given context and all parent contexts apart from topmost context which writes to database */
        let topmostContext = managedContext.saveRecursively()
        
        topmostContext.performAndWait {
            
            if topmostContext.hasChanges {
                
                #if DEBUG
                    for createdObject in topmostContext.insertedObjects {
                        log("Created object in CoreData: \(createdObject.description)")
                    }
                    for modifiedObject in topmostContext.updatedObjects {
                        log("Modified object in CoreData: \(modifiedObject.description)")
                    }
                    for deletedObject in topmostContext.deletedObjects {
                        log("Deleted object in CoreData: \(deletedObject.description)")
                    }
                #endif
                
                do {
                    try topmostContext.save()
                    if let completionHandler = completionHandler {
                        completionHandler(true)
                    }
                } catch let error as NSError {
                    if let completionHandler = completionHandler {
                        completionHandler(false)
                    }
                    log("Failed saving to CoreData: \(error.localizedDescription). Detailed information: \(error.userInfo.description)")
                    return
                }
            }
        }
    }
    
    // MARK: - Convinience functions
    
    /* Function that retrieves all stored records for given entity name in NSManagedObjectContext with .MainQueueConcurrencyType */
    func getAllRecords(ForEntityName entityName: String) -> [UniqueManagedObject] {
        return CoreDataManager.getAllRecords(InContext: viewingContext, ForEntityName: entityName)
    }
    
    /* Function that retrieves stored records satisfying given predicate for given entity name in NSManagedObjectContext with .MainQueueConcurrencyType */
    func getRecords(ForEntityName entityName: String, WithPredicate predicate: NSPredicate) -> [UniqueManagedObject] {
        return CoreDataManager.getRecords(InContext: viewingContext, ForEntityName: entityName, WithPredicate: predicate)
    }
    
    /* Static function that retrieves stored records satisfying given predicate for given ModelObjectType in given NSManagedObjectContext */
    class func getRecords(InContext managedObjectContext: NSManagedObjectContext, ForEntityName entityName: String, WithPredicate predicate: NSPredicate) -> [UniqueManagedObject] {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        do {
            if let fetchResults = try managedObjectContext.fetch(request) as? [UniqueManagedObject] {
                return fetchResults
            } else {
                fatalError("CoreDataManager.getRecords: failed to cast fetched results to [UniqueManagedObject]")
            }
        } catch {
            log("Error fetching records for \(request.entityName): \(error.localizedDescription)")
        }
        return []
    }
    
    /* Static function that retrieves all stored records for given entityName in given NSManagedObjectContext */
    class func getAllRecords(InContext managedObjectContext: NSManagedObjectContext, ForEntityName entityName: String) -> [UniqueManagedObject] {
        return CoreDataManager.getRecords(InContext: managedObjectContext, ForEntityName: entityName, WithPredicate: NSPredicate(value: true))
    }
    
    // MARK: - debug functions
    
    /* Clears all stored records from CoreData */
    func clearData() {
        viewingContext.performAndWait {
            [unowned self] in
            
            self.viewingContext.deleteAllObjects()
            if self.viewingContext.hasChanges {
                do {
                    try self.viewingContext.save()
                } catch let error {
                    fatalError("CoreDataManager.clearData: failed saving to CoreData: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func objectCount() -> Int {
        let entitiesByName = persistentStoreCoordinator.managedObjectModel.entitiesByName
        var totalObjects = 0
        let truePredicate = NSPredicate(value: true)
        let request = NSFetchRequest<NSManagedObject>()
        for (_, entityDescription) in entitiesByName {
            request.entity = entityDescription
            request.predicate = truePredicate
            do {
                totalObjects += try viewingContext.count(for: request)
            } catch let error {
                log("CoreDataManager.objectCount(): failed retrieving object count for \(entityDescription.name). Error is \(error.localizedDescription)")
            }
        }
        return totalObjects
    }
    
    /* For testing purposes: destroys persistent store in given URL if store exists */
    class func destroyPersistentStore(AtURL url: URL) {
        let directoryUrl = url.deletingLastPathComponent()
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let sqliteFiles = directoryContents.filter({
                fileURL in
                return fileURL.absoluteString.contains(".sqlite")
            })
            sqliteFiles.forEach {
                sqliteFile in
                do {
                    try FileManager.default.removeItem(at: sqliteFile)
                } catch let error {
                    log("Failed deleting file at URL \(sqliteFile): \(error)")
                    return
                }
            }
        } catch let error {
            log("Failed to retrieve contents of directory at URL \(directoryUrl): \(error)")
            return
        }
    }
    
}
