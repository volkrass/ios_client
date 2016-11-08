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
    @IBOutlet weak var parcelTitleLabel: UILabel!
    @IBOutlet weak var sentTimeLabel: UILabel!
    @IBOutlet weak var receivedTimeLabel: UILabel!
    @IBOutlet weak var temperatureCategoryLabel: UILabel!
    @IBOutlet weak var contractStatusLabel: UILabel!
    
    override func awakeFromNib() {
        parcelTitleLabel.textColor = MODUM_LIGHT_BLUE
        sentTimeLabel.textColor = MODUM_DARK_BLUE
        receivedTimeLabel.textColor = MODUM_DARK_BLUE
        temperatureCategoryLabel.textColor = MODUM_DARK_BLUE
        contractStatusLabel.textColor = MODUM_DARK_BLUE
    }
    
}
