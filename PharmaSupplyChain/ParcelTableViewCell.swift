//
//  ParcelInfoTableViewCell.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import FoldingCell

class ParcelTableViewCell : FoldingCell {
    
//    @IBOutlet weak var statusIconImageView: UIImageView!
//    @IBOutlet weak var tntNumberLabel: UILabel!
//    @IBOutlet weak var sentTimeLabel: UILabel!
//    @IBOutlet weak var receivedTimeLabel: UILabel!
//    @IBOutlet weak var companyNameLabel: UILabel!
    
//    override func awakeFromNib() {
//        tntNumberLabel.textColor = MODUM_LIGHT_BLUE
//        sentTimeLabel.textColor = MODUM_DARK_BLUE
//        receivedTimeLabel.textColor = MODUM_DARK_BLUE
//        companyNameLabel.textColor = MODUM_DARK_BLUE
//    }
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        super.awakeFromNib()
    }
    
    override func animationDuration(_ itemIndex: NSInteger, type: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.33, 0.26, 0.26]
        return durations[itemIndex]
    }
    
}
