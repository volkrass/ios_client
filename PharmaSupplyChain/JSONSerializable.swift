//
//  JSONSerializable.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Alamofire

protocol JSONSerializable {

    func toJSON() -> Parameters?
    
}

extension JSONSerializable {
    
    /* Generates and returns Parameters array from given JSON string */
    func parameters(FromString string: String) -> Parameters? {
        return string.data(using: String.Encoding.utf8)
            .flatMap{ try? JSONSerialization.jsonObject(with: $0, options: []) }
            .flatMap{ $0 as? [String : AnyObject] }
    }
    
}
