//
//  ParcelDetailTableViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import Charts

class ParcelDetailTableViewController : UITableViewController {
    
    // MARK: CoreData Properties
    
    var parcel: Parcel?
    
    // MARK: Outlets
    
    /* Track&Trace number cell */
    @IBOutlet weak fileprivate var tntNumberNameLabel: UILabel!
    @IBOutlet weak fileprivate var tntNumberLabel: UILabel!
    
    /* Sensor ID cell */
    @IBOutlet weak fileprivate var sensorIDNameLabel: UILabel!
    @IBOutlet weak fileprivate var sensorIDLabel: UILabel!
    
    /* Date sent cell */
    @IBOutlet weak fileprivate var dateSentNameLabel: UILabel!
    @IBOutlet weak fileprivate var dateSentLabel: UILabel!
    
    /* Date received cell */
    @IBOutlet weak fileprivate var dateReceivedNameLabel: UILabel!
    @IBOutlet weak fileprivate var dateReceivedLabel: UILabel!
    
    /* Sender company cell */
    @IBOutlet weak fileprivate var senderCompanyNameLabel: UILabel!
    @IBOutlet weak fileprivate var senderCompanyLabel: UILabel!
    
    /* Receiver company cell */
    @IBOutlet weak fileprivate var receiverCompanyNameLabel: UILabel!
    @IBOutlet weak fileprivate var receiverCompanyLabel: UILabel!
    
    /* Status cell */
    @IBOutlet weak fileprivate var statusNameLabel: UILabel!
    @IBOutlet weak fileprivate var statusLabel: UILabel!
    @IBOutlet weak fileprivate var refreshStatusButton: UIButton!
    
    /* Temperature category cell */
    @IBOutlet weak fileprivate var temperatureCategoryNameLabel: UILabel!
    @IBOutlet weak fileprivate var temperatureCategoryLabel: UILabel!
    
    /* Temperature measuruments graph cell */
    @IBOutlet weak fileprivate var temperatureGraphView: LineChartView!
    
    /* Additional information cell */
    @IBOutlet weak fileprivate var additionalInfoNameLabel: UILabel!
    @IBOutlet weak fileprivate var additionalInfoTextView: UITextView!
    
    
    @IBAction func refreshStatusButtonDidTouchDown(_ sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        guard let parcel = parcel else {
            fatalError("ParcelDetailTableViewController.viewDidLoad(): nil instance of Parcel")
        }
        
        /* UI settings */
        tntNumberNameLabel.textColor = MODUM_DARK_BLUE
        tntNumberLabel.textColor = MODUM_LIGHT_BLUE
        
        sensorIDNameLabel.textColor = MODUM_DARK_BLUE
        sensorIDLabel.textColor = MODUM_LIGHT_BLUE
        
        dateSentNameLabel.textColor = MODUM_DARK_BLUE
        dateSentLabel.textColor = MODUM_LIGHT_BLUE
        
        dateReceivedNameLabel.textColor = MODUM_DARK_BLUE
        dateReceivedLabel.textColor = MODUM_LIGHT_BLUE
        
        senderCompanyNameLabel.textColor = MODUM_DARK_BLUE
        senderCompanyLabel.textColor = MODUM_LIGHT_BLUE
        
        receiverCompanyNameLabel.textColor = MODUM_DARK_BLUE
        receiverCompanyLabel.textColor = MODUM_LIGHT_BLUE
        
        statusNameLabel.textColor = MODUM_DARK_BLUE
        statusLabel.textColor = MODUM_LIGHT_BLUE
        refreshStatusButton.tintColor = MODUM_LIGHT_BLUE
        
        temperatureCategoryNameLabel.textColor = MODUM_DARK_BLUE
        temperatureCategoryLabel.textColor = MODUM_LIGHT_BLUE
        
        additionalInfoNameLabel.textColor = MODUM_DARK_BLUE
        additionalInfoTextView.textColor = MODUM_LIGHT_BLUE
        
        /* setup temperature measurement graph */
        temperatureGraphView.noDataText = "No temperature measurements to display"
        temperatureGraphView.noDataTextColor = MODUM_DARK_BLUE
        
        temperatureGraphView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        
        fillDataFields(FromParcel: parcel)
    }
    
    fileprivate func fillDataFields(FromParcel parcel: Parcel) {
        tntNumberLabel.text = parcel.tntNumber
        sensorIDLabel.text = parcel.sensorMAC
        dateSentLabel.text = parcel.dateSent.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        if let dateReceived = parcel.dateReceived {
            dateReceivedLabel.text = dateReceived.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            dateReceivedLabel.text = "-"
        }
        senderCompanyLabel.text = parcel.senderCompany
        receiverCompanyLabel.text = parcel.receiverCompany ?? "-"
        statusLabel.text = parcel.getStatus().rawValue
        temperatureCategoryLabel.text = parcel.tempCategory
        additionalInfoNameLabel.text = parcel.additionalInfo ?? "-"
    }
    
}
