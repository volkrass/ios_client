//
//  TemperatureGradientLine.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 21.02.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit

class TemperatureGradientLine : UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        
        /* check if we have already added gradient layer */
        if let sublayers = layer.sublayers {
            for layer in sublayers {
                if layer is CAGradientLayer {
                    return
                }
            }
        }
        
        let leftColor = TEMPERATURE_LIGHT_BLUE.cgColor
        let rightColor = TEMPERATURE_LIGHT_RED.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [leftColor, rightColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
}
