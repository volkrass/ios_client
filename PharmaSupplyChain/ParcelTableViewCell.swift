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
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var companyNameLabel: UILabel!
    @IBOutlet weak fileprivate var statusView: UIView!
    @IBOutlet weak fileprivate var sentTimeLabel: UILabel!
    @IBOutlet weak fileprivate var tntNumberLabel: UILabel!
    @IBOutlet weak fileprivate var receivedTimeLabel: UILabel!
    
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
