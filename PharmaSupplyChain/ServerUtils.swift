//
//  ServerUtils.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation

/*
 Converts date strings supplied by the server into Date
 The example string is:
    2016-12-16T19:38:32+01:00
 */
func date(FromServerString serverString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter.date(from: serverString)
}
