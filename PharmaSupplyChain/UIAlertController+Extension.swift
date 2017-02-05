//
//  UIAlertController+Extension.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 05.02.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    func addDismissAction(WithHandler handler: @escaping ((UIAlertAction) -> Void)) -> UIAlertController {
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: handler)
        addAction(dismissAction)
        
        return self
    }
    
}
