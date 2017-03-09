//
//  CompanyDefaults.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class CompanyDefaults : Mappable/*, CoreDataObject */ {
    
    fileprivate let PLIST_FILE = "CompanyDefault.plist"
    
    // MARK: Properties
    
    var defaultTemperatureCategoryIndex: Int?
    var defaultMeasurementInterval: Int?
    var companyTemperatureCategories: [CompanyTemperatureCategory]?
    
    // MARK: Public functions
    
    func toPlistFile() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if !paths.isEmpty, let documentsPath = URL(string: paths[0]) {
            let plistFilePath = documentsPath.appendingPathComponent(PLIST_FILE)
            
            //let plistPath = do
        }
    }
    
    func fromPlistFile() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    }
    
    // MARK: Mappable
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        defaultTemperatureCategoryIndex <- map["defaultTemperatureCategoryIndex"]
        defaultMeasurementInterval <- map["defaultMeasurementInterval"]
        companyTemperatureCategories <- map["temperatureCategories"]
    }
    
    
    
}
