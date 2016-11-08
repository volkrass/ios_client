//
//  ServerUtils.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


class ServerUtils {
    
    /*
     Converts date strings supplied by the server into Date
     The example string is:
     2016-12-16T19:38:32+01:00
     */
    static func date(FromServerString serverString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.date(from: serverString)
    }
    
    /*
     Converts date into the string in the format recognized by the server
     The example conversion is:
     Date -> 2016-12-16T19:38:32+01:00
     */
    static func serverDateString(FromDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.string(from: date)
    }
    
    /* Generates and returns Parameters array from given JSON string */
    static func parameters(FromString string: String) -> Parameters? {
        return string.data(using: String.Encoding.utf8)
            .flatMap{ try? JSONSerialization.jsonObject(with: $0, options: []) }
            .flatMap{ $0 as? [String : AnyObject] }
    }
    
    /* Generates and returns Parameters array from given JSON object */
    static func parameters(FromJSON json: JSON) -> Parameters? {
        if let jsonString = json.rawString() {
            return parameters(FromString: jsonString)
        } else {
            return nil
        }
    }
    
}



