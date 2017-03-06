//
//  ServerDateTransform.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 06.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import ObjectMapper

class ServerDateTransform : TransformType {
    
    /* If date from the server-side is to set to nil, server automatically sets this value */
    static let serverNilDateString: String = "0001-01-01T00:34:08+00:34"
    
    typealias Object = Date
    typealias JSON = String
    
    public init() {}
    
    public func transformFromJSON(_ value: Any?) -> Date? {
        let dateFormatter = Date.iso8601Formatter
        if let dateValue = value as? String {
            if dateValue == ServerDateTransform.serverNilDateString {
                return nil
            } else {
                return dateFormatter.date(from: dateValue)
            }
        } else {
            return nil
        }
    }
    
    public func transformToJSON(_ value: Date?) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let date = value {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    
}
