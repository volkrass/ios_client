//
//  UILoadingView.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit

class UILoadingView : UIView {
    
    // MARK: Properties
    
    fileprivate let activityIndicator: UIActivityIndicator
    fileprivate let infoLabel: UILabel
    
    init(rect: CGRect) {
        /* adding activity indicator */
        activityIndicator = UIActivityIndicator(frame: CGRect(x: rect.width/2 - 50.0, y: rect.minY + 50.0, width: 100.0, height: 100.0))
        
        /* adding info label */
        infoLabel = UILabel(frame: CGRect(x: rect.minX + 25.0, y: rect.height + 75.0, width: rect.width - 50.0, height: 25.0))
        infoLabel.font = UIFont(name: "OpenSans-Light", size: 20.0)
        infoLabel.textColor = IOS7_BLUE_COLOR
        infoLabel.textAlignment = .center
        
        super.init(frame: rect)
        
        backgroundColor = UIColor.white
        
        addSubview(activityIndicator)
        bringSubview(toFront: activityIndicator)
        addSubview(infoLabel)
        bringSubview(toFront: infoLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(text: String) {
        infoLabel.text = text
    }
    
    func startAnimating() {
        activityIndicator.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicator.stopAnimating()
    }
    
}
