//
//  CoreDataManagerTests.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 3.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import XCTest
import CoreData
@testable import PharmaSupplyChain

class CoreDataManagerTests: XCTestCase {
    
    fileprivate var coreDataManager: CoreDataManager?
    
    override func setUp() {
        super.setUp()
        let destinationURL = CoreDataManager.storeURL
        let testingBundle = Bundle.init(for: CoreDataManagerTests.self)
        let sourceURL = testingBundle.url(forResource: "Test2", withExtension: "sqlite")
        //try! FileManager.default.removeItem(at: destinationURL)
        CoreDataManager.destroyPersistentStore(AtURL: destinationURL)
        try! FileManager.default.copyItem(at: sourceURL!, to: destinationURL)
        coreDataManager = CoreDataManager()
    }
    
    override func tearDown() {
        let url = CoreDataManager.storeURL
        CoreDataManager.destroyPersistentStore(AtURL: url)
        coreDataManager = nil
        super.tearDown()
    }
    
    /*
     Tests whether CoreDataManager.saveLocally(_: NSManagedObjectContext, _: Bool) actually writes to persistent store from viewing context
     */
    func testSaveFromViewingContext() {
        let beforeInsertObjectCount = coreDataManager!.objectCount()
        XCTAssert(beforeInsertObjectCount == 0)
        let objectCount = 10000
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext)
        sleep(1)
        coreDataManager!.viewingContext.reset()
        let request: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
        request.predicate = NSPredicate(value: true)
        let fetchResults = try! coreDataManager!.viewingContext.fetch(request)
        XCTAssert(fetchResults.count == objectCount)
    }
    
    /*
     Tests whether CoreDataManager.saveLocally(_: NSManagedObjectContext, _: Bool) actually writes to persistent store from background context
     */
    func testSaveFromBackgroundContext() {
        let beforeInsertObjectCount = coreDataManager!.objectCount()
        XCTAssert(beforeInsertObjectCount == 0)
        let objectCount = 10000
        coreDataManager!.performBackgroundTask(WithBlock: {
            [unowned self]
            backgroundContext in
            
            for i in 1...objectCount {
                let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: backgroundContext) as! TestEntity
                testEntityObject.name = "Test\(i)"
                testEntityObject.createdAt = Date()
            }
            self.coreDataManager!.saveLocally(managedContext: backgroundContext)
            sleep(1)
        })
        
        let request: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
        request.predicate = NSPredicate(value: true)
        let fetchResults = try! coreDataManager!.viewingContext.fetch(request)
        XCTAssert(fetchResults.count == objectCount)
    }
    
    /*
     Tests whether CoreDataManager.saveLocally(_: NSManagedObjectContext, _: Bool) returns completionHander(false) if writing to persistent store failed
    */
    func testSaveReturnsFalseCompletionHandler() {
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            /* non-optional 'createdAt' field isn't initialised on purpose, so saving to persisten fails with NSValidationError */
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext, WithCompletionHandler: {
            success in
            
            XCTAssert(!success)
        })
    }
    
    /*
     Tests whether CoreDataManager.saveLocally(_: NSManagedObjectContext, _: Bool) returns completionHander(true) if writing to persistent store succeeded
    */
    func testSaveReturnsTrueCompletionHandler() {
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext, WithCompletionHandler: {
            success in
            
            XCTAssert(success)
        })
    }
    
    /* Tests whether CoreDataManager.getRecords(ForObjectType _: ModelObjectType, WithPredicate _: NSPredicate) instance function returns same number of records as has been inserted for 'true' predicate */
    func testGetRecords1() {
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext)
        sleep(1)
        let fetchResults = coreDataManager!.getRecords(ForEntityName: "TestEntity", WithPredicate: NSPredicate(value: true))
        XCTAssert(fetchResults.count == objectCount)
    }
    
    /* Tests whether CoreDataManager.getRecords(ForObjectType _: ModelObjectType, WithPredicate _: NSPredicate) instance function returns zero records if no records should match the given predicate */
    func testGetRecords2() {
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext)
        sleep(1)
        let fetchResults = coreDataManager!.getRecords(ForEntityName: "TestEntity", WithPredicate: NSPredicate(format: "identifier == %@", ProcessInfo.processInfo.globallyUniqueString))
        XCTAssert(fetchResults.count == 0)
    }
    
    /* Tests whether CoreDataManager.getRecords(ForObjectType _: ModelObjectType, WithPredicate _: NSPredicate) instance function returns zero records if no records are saved in the database */
    func testGetRecords3() {
        let fetchResults = coreDataManager!.getRecords(ForEntityName: "TestEntity", WithPredicate: NSPredicate(value: true))
        XCTAssert(fetchResults.count == 0)
    }
    
    /* Tests whether CoreDataManager.getAllRecords(InContext _: NSManagedObjectContext, ForObjectType _: ModelObjectType) fetches saved records correctly from background thread */
    func testGetAllRecordsStaticFromBackground() {
        coreDataManager!.performBackgroundTask(WithBlock: {
            [unowned self]
            backgroundContext in
            
            let objectCount = 10000
            /* populate database */
            for i in 1...objectCount {
                let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: backgroundContext) as! TestEntity
                testEntityObject.name = "Test\(i)"
                testEntityObject.createdAt = Date()
            }
            self.coreDataManager!.saveLocally(managedContext: backgroundContext)
            sleep(1)
            
            let fetchResults = CoreDataManager.getAllRecords(InContext: backgroundContext, ForEntityName: "TestEntity")
            XCTAssert(fetchResults.count == objectCount)
        })
    }
    
    /* Tests whether CoreDataManager.getAllRecords(InContext _: NSManagedObjectContext, ForObjectType _: ModelObjectType) fetches saved records correctly from main thread */
    func testGetAllRecordsStaticFromMain() {
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext)
        sleep(1)
        
        let fetchResults = CoreDataManager.getAllRecords(InContext: coreDataManager!.viewingContext, ForEntityName: "TestEntity")
        XCTAssert(fetchResults.count == objectCount)
    }
    
    /* Tests CoreDataManager.objectCount() function */
    func testObjectCount() {
        XCTAssert(coreDataManager!.objectCount() == 0)
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext)
        sleep(1)

        let afterObjectCount = coreDataManager!.objectCount()
        XCTAssert(afterObjectCount == objectCount)
    }
    
    /* Tests CoreDataManager.clearData() function */
    func testClearData1() {
        XCTAssert(coreDataManager!.objectCount() == 0)
        coreDataManager!.clearData()
        XCTAssert(coreDataManager!.objectCount() == 0)
    }
    
    /* Tests CoreDataManager.clearData() function */
    func testClearData2() {
        XCTAssert(coreDataManager!.objectCount() == 0)
        
        let objectCount = 10000
        /* populate database */
        for i in 1...objectCount {
            let testEntityObject = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: coreDataManager!.viewingContext) as! TestEntity
            testEntityObject.name = "Test\(i)"
            testEntityObject.createdAt = Date()
        }
        
        coreDataManager!.saveLocally(managedContext: coreDataManager!.viewingContext)
        sleep(1)
        
        coreDataManager!.clearData()

        XCTAssert(coreDataManager!.objectCount() == 0)
    }
    
    /* Tests CoreDataManager.destroyPersistentStore(AtURL _: NSURL) function whether it actually removes underlying persistent store and it's associated files from the disk */
    func testDestroyPersistentStoreAtUrl() {
    
        let storeURL = CoreDataManager.storeURL
        let directoryURL = storeURL.deletingLastPathComponent()
        
        /* assert that there are persistent store files at given URL */
        var directoryContents = try! FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var fileExtensions = directoryContents.flatMap({ $0.pathExtension })
        var sqliteFiles = fileExtensions.filter({
            pathExtension in
            return pathExtension.contains("sqlite")
        })
        /* There should be at least 1 file with extension containing .sqlite */
        XCTAssert(sqliteFiles.count >= 1)
        
        CoreDataManager.destroyPersistentStore(AtURL: storeURL)
        
        /* assert that there are no more persistent store associated files at given URL */
        directoryContents = try! FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        fileExtensions = directoryContents.flatMap({ $0.pathExtension })
        sqliteFiles = fileExtensions.filter ({
            pathExtension in
            return pathExtension.contains("sqlite")
        })
        /* There should be no files with extension containing .sqlite */
        XCTAssert(sqliteFiles.count == 0)
    }

}
