//
//  Logging.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation

/*
 The function to be used for logging throughout the project
 All calls to "print" should be replaced with "log"
 */
func log(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
    #if DEBUG
        let url = NSURL(fileURLWithPath: file)
        guard let filename = url.deletingPathExtension?.lastPathComponent else {
            fatalError("Utils.log: failed to retrieve lastPathComponent")
        }
        print("\(message) [\(filename).\(function):\(line)]")
    #endif
}

/* Returns an array containing unique values which conform to Hashable */
func uniq<S: Sequence, E: Hashable>(_ source: S) -> [E] where E == S.Iterator.Element {
    var seen = [E: Bool]()
    return source.filter { seen.updateValue(true, forKey: $0) == nil }
}
