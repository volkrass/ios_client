//
//  ReccurentUploader.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 12.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

/* 
 Singleton class responsible for reccurently uploading data which failed to upload
 */
class RecurrentUploader {
    
    // MARK: Properties
    
    static let shared = RecurrentUploader()
    
    // MARK: Constants
    
    private init() {}
    
    func resumeDownloads() {
        
    }
    
    func stopDownloads() {
        
    }
    
    func addMeasurementsToUpload(tntNumber: String, sensorMAC: String, measurements: [TemperatureMeasurement]) {
        
    }
    
    func addParcelToUpload(parcel: CreatedParcel) {
        
    }
    
}
