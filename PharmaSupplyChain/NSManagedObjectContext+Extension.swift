//
//  NSManagedObjectContext+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    
    /*
     Saves current NSManagedObjectContext and all it's parent contexts, apart from the topmost NSManagedObjectContext
     If current NSManagedObjectContext has no parent contexts, returns self
     */
    func saveRecursively() -> NSManagedObjectContext {
        //if parent == nil, we reached topmost context
        guard parent != nil else {
            return self
        }
        var successfullySaved = true
        performAndWait ({
            [weak self] in
            
            if let context = self, context.hasChanges {
                do {
                    try context.save()
                } catch let error as NSError {
                    successfullySaved = false
                   log("NSManagedObjectContext.saveRecursively(): \(error.localizedDescription). Detailed information: \(error.userInfo.description)")
                }
            } else {
                successfullySaved = false
            }
        })
        if !successfullySaved {
            return self
        } else {
            return parent!.saveRecursively()
        }
    }
    
    /*
     Given list of 'identifier' from UniqueManagedObject, fetches corresponding NSManagedObject
     Identifier format: <entity name>.<UUID>
     */
    func fetchRecords(WithIdentifiers ids: [String]) -> [NSManagedObject] {
        /* Extract entity name from identifier */
        var recordTypes = Set<String>()
        for id in ids {
            if let dotIndex = id.characters.index(of: ".") {
                let recordType = id.substring(to: dotIndex)
                recordTypes.insert(recordType)
            }
        }
        /* Form fetch request for every entity */
        var results: [NSManagedObject] = []
        for recordType in recordTypes {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: recordType)
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", ids)
            do {
                if let response = try fetch(fetchRequest) as? [NSManagedObject] {
                    results.append(contentsOf: response)
                }
            } catch let error {
                log("Failed to execute fetch request: \(error.localizedDescription)")
            }
        }
        return results
    }
    
    func getEntities(IfUserInfoKeyPresent userInfoKey: String) -> [String] {
        var entities: [String] = []
        if let persistentStoreCoordinator = persistentStoreCoordinator {
            let availableEntities = persistentStoreCoordinator.managedObjectModel.entities
            for entity in availableEntities {
                if let userInfo = entity.userInfo, let entityName = entity.name {
                    if userInfo.keys.contains(userInfoKey) {
                        entities.append(entityName)
                    }
                }
            }
        }
        return entities
    }
    
    /*
     Returns NSManagedObject array containing NSManagedObject instances with given @name registered within the context
     If no matching objects are found within this context, return empty array
     */
    func dumpRegisteredObjects(ForEntityName entityName: String) -> [NSManagedObject] {
        var results: [NSManagedObject] = []
        for registeredObject in registeredObjects {
            if let entityName = registeredObject.entity.name {
                if entityName.compare(entityName) == .orderedSame {
                    results.append(registeredObject)
                }
            }
        }
        return results
    }
    
    /* Prints description of all object registered within the context */
    func dumpRegisteredObjects() {
        for registeredObject in registeredObjects {
            log(registeredObject.description)
        }
    }
    
    /* wipes entire contents of associated persistent store */
    func deleteAllObjects() {
        if let entitiesByName = persistentStoreCoordinator?.managedObjectModel.entitiesByName {
            for (_, entityDescription) in entitiesByName {
                deleteAllObjectsForEntity(entityDescription)
            }
        }
    }
    
    /* wipes all objects for given entity type in associated store coordinator */
    func deleteAllObjectsForEntity(_ entity: NSEntityDescription) {
        let fetchRequest = NSFetchRequest<NSManagedObject>()
        fetchRequest.entity = entity
        do {
            let fetchResults = try fetch(fetchRequest)
            for result in fetchResults {
                log("Deleting object \(result.objectID)...")
                delete(result)
            }
        } catch let error {
            log("Error clearing CoreData entity \(entity): \(error.localizedDescription)")
            return
        }
    }
}
