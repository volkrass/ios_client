//
//  String+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 07.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import Foundation

extension String {
    
    func base64DecodedString() -> String? {
        if let decodedData = self.base64DecodedData(), let decodedString = String(data: decodedData, encoding: .utf8) {
            return decodedString
        } else {
            return nil
        }
    }
    
    func base64DecodedData() -> Data? {
        let validBase64String = convertToValidBase64String(string: self)
        return Data(base64Encoded: validBase64String)
    }
    
    fileprivate func convertToValidBase64String(string: String) -> String {
        /* Base64 string length should be divisible by 4 */
        var validBase64String = string
        while (validBase64String.characters.count % 4 != 0) {
            validBase64String.characters.append("=")
        }
        return validBase64String
    }
    
    func indexOf(target: String) -> Int? {
        if let range = self.range(of: target) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
    func lastIndexOf(target: String) -> Int? {
        if let range = self.range(of: target, options: .backwards) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
}
