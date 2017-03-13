//
//  CompanyDefaults.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper
import CoreData

class CompanyDefaults : Mappable, CoreDataObject {
    
    // MARK: Properties
    
    var defaultTemperatureCategoryIndex: Int?
    var defaultMeasurementInterval: Int?
    var companyTemperatureCategories: [CompanyTemperatureCategory] = []
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        defaultTemperatureCategoryIndex <- map["defaultTemperatureCategoryIndex"]
        defaultMeasurementInterval <- map["defaultMeasurementInterval"]
        companyTemperatureCategories <- map["temperatureCategories"]
    }
    
    // MARK: CoreDataObject
    
    public required init?(WithCoreDataObject object: CDCompanyDefaults) {
        defaultMeasurementInterval = object.defaultMeasurementInterval
        if let companyTemperatureCategories = Array(object.tempCategories) as? [CDTempCategory] {
            self.companyTemperatureCategories = companyTemperatureCategories.flatMap{ CompanyTemperatureCategory(WithCoreDataObject: $0) }
        }
        defaultTemperatureCategoryIndex = companyTemperatureCategories.index(where: {
            tempCategory in
            
            if let minTemp = tempCategory.tempLow, let maxTemp = tempCategory.tempHigh {
                return object.defaultTempCategory.minTemp == minTemp && object.defaultTempCategory.maxTemp == maxTemp
            } else {
                return false
            }
        })
    }
    
    public func toCoreDataObject(object: CDCompanyDefaults) {
        if let defaultMeasurementInterval = defaultMeasurementInterval, let defaultTemperatureCategoryIndex = defaultTemperatureCategoryIndex {
            object.defaultMeasurementInterval = defaultMeasurementInterval
            if let context = object.managedObjectContext {
                object.tempCategories = NSSet()
                for tempCategory in companyTemperatureCategories {
                    let cdTempCategory = NSEntityDescription.insertNewObject(forEntityName: "CDTempCategory", into: context) as! CDTempCategory
                    tempCategory.toCoreDataObject(object: cdTempCategory)
                    object.addToTempCategories(cdTempCategory)
                }
                if defaultTemperatureCategoryIndex >= 0 && defaultTemperatureCategoryIndex < companyTemperatureCategories.count && !companyTemperatureCategories.isEmpty {
                    let tempCategory = companyTemperatureCategories[defaultTemperatureCategoryIndex]
                    
                    let cdTempCategory = NSEntityDescription.insertNewObject(forEntityName: "CDTempCategory", into: context) as! CDTempCategory
                    tempCategory.toCoreDataObject(object: cdTempCategory)
                    object.defaultTempCategory = cdTempCategory
                }
            }
        }
    }
    
}
