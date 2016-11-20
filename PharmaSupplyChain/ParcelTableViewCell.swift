//
//  ParcelInfoTableViewCell.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit

class ParcelTableViewCell : UITableViewCell {
    
    @IBOutlet weak var statusIconImageView: UIImageView!
    @IBOutlet weak var tntNumberLabel: UILabel!
    @IBOutlet weak var sentTimeLabel: UILabel!
    @IBOutlet weak var receivedTimeLabel: UILabel!
    @IBOutlet weak var companyNameLabel: UILabel!
    
    override func awakeFromNib() {
        tntNumberLabel.textColor = MODUM_LIGHT_BLUE
        sentTimeLabel.textColor = MODUM_DARK_BLUE
        receivedTimeLabel.textColor = MODUM_DARK_BLUE
        companyNameLabel.textColor = MODUM_DARK_BLUE
    }
    
}
