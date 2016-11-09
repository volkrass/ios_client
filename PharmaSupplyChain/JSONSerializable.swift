//
//  JSONSerializable.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import SwiftyJSON

protocol JSONSerializable {

    func toJSON() -> JSON?
  
    func fromJSON(object: JSON)
}
