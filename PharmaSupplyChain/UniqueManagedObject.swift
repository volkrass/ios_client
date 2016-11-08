//
//  UniqueManagedObject.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 08.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation

/*
 'NSManagedObject.objectID' cannot be safely used to uniquely identify NSManagedObject
 Every NSManagedObject should comply to UniqueManagedObject which stores unique ID field
 */
@objc protocol UniqueManagedObject {
    
    var identifier: String {get set}
    
}
