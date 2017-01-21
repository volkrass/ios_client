//
//  Sequence+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.01.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import Foundation

extension Array where Element:Hashable {
    
    func contains(Array otherArray: [Element]) -> Bool {
        let thisArraySet = Set(self)
        let otherArraySet = Set(otherArray)
        return otherArraySet.isSubset(of: thisArraySet)
    }
    
}
