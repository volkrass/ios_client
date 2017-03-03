//
//  ServerError.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 03.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class ServerError: Mappable {
    
    static let defaultError: ServerError = ServerError(code: nil, message: "Server error occured. Please, try again!")
    
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
    
}
