//
//  ParcelDetailTableViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 13.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import Charts

class ParcelDetailTableViewController : UITableViewController, ChartViewDelegate {
    
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
        
        /* Charts setup */
        temperatureGraphView.delegate = self
        
        temperatureGraphView.dragEnabled = true
        temperatureGraphView.pinchZoomEnabled = false
        temperatureGraphView.drawGridBackgroundEnabled = false
        temperatureGraphView.backgroundColor = UIColor.white
        temperatureGraphView.leftAxis.drawGridLinesEnabled = false
        temperatureGraphView.rightAxis.drawGridLinesEnabled = false
        temperatureGraphView.xAxis.drawGridLinesEnabled = false
        temperatureGraphView.chartDescription?.text = ""
        temperatureGraphView.legend.enabled = false
        temperatureGraphView.noDataText = "No temperature measurements to display"
        temperatureGraphView.noDataTextColor = MODUM_DARK_BLUE
        
        let maxTempLimitLine = ChartLimitLine(limit: Double(parcel.maxTemp), label: "Maximum Temperature")
        let minTempLimitLine = ChartLimitLine(limit: Double(parcel.minTemp), label: "Minimum Temperature")
        if let helveticaNeueLightFont = UIFont(name: "HelveticaNeue-Light", size: 9.0) {
            maxTempLimitLine.valueFont = helveticaNeueLightFont
            minTempLimitLine.valueFont = helveticaNeueLightFont
        }
        temperatureGraphView.rightAxis.addLimitLine(maxTempLimitLine)
        temperatureGraphView.leftAxis.addLimitLine(minTempLimitLine)
        
        /* TODO: replace mock measurement data with the actual data */
        let temperatures = [15.6, 16.8, 21.5, 22.3, 24.5, 28.7, 11.3, 20.0, 25.2, 18.4]
        let timestamps = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
        
        var dataEntries: [ChartDataEntry] = []
        for index in 0..<timestamps.count {
            let dataEntry = ChartDataEntry(x: Double(timestamps[index]), y: temperatures[index])
            dataEntries.append(dataEntry)
        }
        let dataSet = LineChartDataSet(values: dataEntries, label: "Temperature")
        dataSet.circleColors = [UIColor.red]
        
        let gradientColors = [UIColor.red.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations: [CGFloat] = [1.0, 0.0]
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations)
        dataSet.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
        dataSet.drawFilledEnabled = true
        
        temperatureGraphView.data = LineChartData(dataSets: [dataSet])

        temperatureGraphView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        
        fillDataFields(FromParcel: parcel)
        
        /* UI configuration */
        tableView.estimatedRowHeight = 82
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /* For temperature measurements graph, return 250 height */
        if indexPath.row == 8 {
            return 250
        } /* For additional info UITextView, return automatic height */
        else if indexPath.row == 9 {
            if parcel!.additionalInfo == nil || parcel?.additionalInfo == "" {
                return 0
            } else {
                return UITableViewAutomaticDimension
            }
        } else {
            return 82
        }
    }
    
    // MARK: Helper functions
    
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
        receiverCompanyLabel.text = parcel.receiverCompany 
        statusLabel.text = parcel.getStatus().rawValue
        temperatureCategoryLabel.text = parcel.tempCategory
        additionalInfoTextView.text = parcel.additionalInfo ?? "-"
    }
    
}
