//
//  ServerError.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class ServerError: Mappable, Equatable {
    
    // MARK: Constants
    
    /* General errors */
    static let defaultError: ServerError = ServerError(code: nil, message: "Server error occured. Please, try again!")
    static let noInternet: ServerError = ServerError(code: nil, message: "No network connection!")
    
    /* Parcel creation errors */
    static let parcelTntAlreadyExists: ServerError = ServerError(code: nil, message: "Parcel with this TNT number already exists!")
    static let parcelMaxFailsIncorrect: ServerError = ServerError(code: nil, message: "Maximum allowed temperature failures is set incorrectly!")
    
    /* Measurement upload errors */
    static let measurementsForParcelAlreadyExist: ServerError = ServerError(code: nil, message: "Measurements for parcel have already been uploaded!")
    static let parcelWithTntNotExists: ServerError = ServerError(code: nil, message: "There is no matching parcel for which these measurements should be uploaded")
    
    // MARK: Properties

    var code: Int?
    var message: String?
    
    // MARK: Public functions
    
    init(code: Int?, message: String) {
        self.code = code
        self.message = message
    }
    
    // MARK: Mappable
    
    required init?(map: Map) {
        if map.JSON["message"] == nil || map.JSON["code"] == nil {
            return nil
        }
    }
    
    func mapping(map: Map) {
        code <- map["code"]
        message <- map["message"]
    }
    
    // MARK: Equatable
    
    static public func ==(lhs: ServerError, rhs: ServerError) -> Bool {
        return lhs.code == rhs.code && lhs.message == rhs.message
    }
    
}
