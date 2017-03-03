//
//  ParcelInfoTableViewCell.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import FoldingCell
import Charts

class ParcelTableViewCell : FoldingCell, ChartViewDelegate {
    
    // MARK: Properties
    
    fileprivate var parcel: Parcel?
    
    // MARK: Constants
    
    fileprivate let openCellHeight: CGFloat = 510
    
    // MARK: Outlets
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var sentTimeLabel: UILabel!
    @IBOutlet weak var tntNumberLabel: UILabel!
    @IBOutlet weak var receivedTimeLabel: UILabel!
    
    /* Detail cell */
    @IBOutlet weak fileprivate var parcelDetailView: UIView!
    @IBOutlet weak var detailStatusView: UIView!
    @IBOutlet weak var detailTntNumberLabel: UILabel!
    @IBOutlet weak var detailSentTimeLabel: UILabel!
    @IBOutlet weak var detailReceivedTimeLabel: UILabel!
    @IBOutlet weak var detailSenderCompanyLabel: UILabel!
    @IBOutlet weak var detailReceiverCompanyLabel: UILabel!
    @IBOutlet weak var detailTempMinLabel: UILabel!
    @IBOutlet weak var detailTempMaxLabel: UILabel!
    @IBOutlet weak fileprivate var detailTempLine: UIView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var infoIcon: UIImageView!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var temperatureGraphView: LineChartView!
    
    // MARK: Actions
    
    @IBAction fileprivate func smartContactStatusButtonTouchUpInside(_ sender: UIButton) {
        if let parcel = parcel, let tntNumber = parcel.tntNumber, let sensorID = parcel.sensorID {
            /* fetch temperature measurements blockchain status */
            ServerManager.shared.getTemperatureMeasurementsStatus(tntNumber: tntNumber, sensorID: sensorID, completionHandler: {
                error, smartContractStatus in
                
                if let error = error {
                    /* TODO: design view indicating error */
                } else if let smartContractStatus = smartContractStatus {
                    if let isMined = smartContractStatus.isMined {
                        /* display status image view */
                    }
                }
            })
        }
    }
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10.0
        foregroundView.layer.masksToBounds = true
        
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
        
        super.awakeFromNib()
    }
    
    override func animationDuration(_ itemIndex: NSInteger, type: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.33, 0.26, 0.26]
        return durations[itemIndex]
    }
    
    // MARK: Public functions
    
    /* fills ParcelTableView fields from Parcel object and returns height of cell */
    func fill(FromParcel parcel: Parcel) -> CGFloat {
        self.parcel = parcel
        if let parcelTnt = parcel.tntNumber, let sensorID = parcel.sensorID {
            /* fetch temperature measurements */
            ServerManager.shared.getTemperatureMeasurements(tntNumber: parcelTnt, sensorID: sensorID, completionHandler: {
                [weak self]
                error, temperatureMeasurements in
                
                if let parcelCell = self {
                    if let error = error {
                        /* TODO: design view indicating error */
                    } else if let temperatureMeasurements = temperatureMeasurements, let minTemp = parcel.minTemp, let maxTemp = parcel.maxTemp {
                        parcelCell.displayMeasurements(measurements: temperatureMeasurements, minTemp: minTemp, maxTemp: maxTemp)
                    }
                }
            })
            
            /* fetch temperature measurements blockchain status */
            ServerManager.shared.getTemperatureMeasurementsStatus(tntNumber: parcelTnt, sensorID: sensorID, completionHandler: {
                [weak self]
                error, smartContractStatus in
                
                if let parcelCell = self {
                    if let error = error {
                        /* TODO: design view indicating error */
                    } else if let smartContractStatus = smartContractStatus {
                        if let isMined = smartContractStatus.isMined {
                            /* display status image view */
                        }
                    }
                }
            })
        }
        
        /* filling in parcel detail information */
        if let parcelStatus = parcel.status {
            switch parcelStatus {
            case .inProgress:
                detailStatusView.backgroundColor = STATUS_ORANGE
            case .notWithinTemperatureRange:
                detailStatusView.backgroundColor = STATUS_RED
            case .successful:
                detailStatusView.backgroundColor = STATUS_GREEN
            case .undetermined:
                detailStatusView.backgroundColor = UIColor.gray
            }
        } else {
            detailStatusView.backgroundColor = UIColor.gray
        }
        detailTntNumberLabel.text = parcel.tntNumber
        if let dateSent = parcel.dateSent {
            detailSentTimeLabel.text = dateSent.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            detailSentTimeLabel.text = "-"
        }
        if let dateReceived = parcel.dateReceived {
            detailReceivedTimeLabel.text = dateReceived.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            detailReceivedTimeLabel.text = "-"
        }
        detailSenderCompanyLabel.text = parcel.senderCompany ?? "-"
        detailReceiverCompanyLabel.text = parcel.receiverCompany ?? "-"
        if let minTemp = parcel.minTemp, let maxTemp = parcel.maxTemp {
            detailTempMinLabel.text = String(minTemp) + "℃"
            detailTempMaxLabel.text = String(maxTemp) + "℃"
        } else {
            detailTempMinLabel.text = "-℃"
            detailTempMaxLabel.text = "-℃"
        }
        statusImageView.image = UIImage(named: "status_unknown")
        
        if let additionalInfo = parcel.additionalInfo, !additionalInfo.isEmpty {
            infoTextView.text = additionalInfo
        } else {
            let cellHeightWithoutInfo = hideInfoTextView()
            if let cellHeightWithoutInfo = cellHeightWithoutInfo {
                return cellHeightWithoutInfo
            } else {
                return openCellHeight
            }
        }
        
        return openCellHeight
    }
    
    // MARK: Helper functions
    
    fileprivate func displayMeasurements(measurements: [TemperatureMeasurement], minTemp: Int, maxTemp: Int) {
        let maxTempLimitLine = ChartLimitLine(limit: Double(maxTemp), label: "Maximum Temperature")
        let minTempLimitLine = ChartLimitLine(limit: Double(minTemp), label: "Minimum Temperature")
        if let openSansLightFont = UIFont(name: "OpenSans-Light", size: 9.0) {
            maxTempLimitLine.valueFont = openSansLightFont
            minTempLimitLine.valueFont = openSansLightFont
        }
        
        temperatureGraphView.leftAxis.axisMinimum = Double(minTemp) - 5.0
        temperatureGraphView.leftAxis.axisMaximum = Double(maxTemp) + 5.0
        
        temperatureGraphView.rightAxis.enabled = false
        
        temperatureGraphView.leftAxis.addLimitLine(maxTempLimitLine)
        temperatureGraphView.leftAxis.addLimitLine(minTempLimitLine)
        
//        let temperatures = measurements.flatMap{ $0.temperature }
//        let timestamps = measurements.flatMap{ $0.timestamp?.timeIntervalSince1970 }
//        
//        var dataEntries: [ChartDataEntry] = []
//        for index in 0..<timestamps.count {
//            let dataEntry = ChartDataEntry(x: Double(timestamps[index]), y: temperatures[index])
//            dataEntries.append(dataEntry)
//        }
//        let dataSet = LineChartDataSet(values: dataEntries, label: "Temperature")
//        dataSet.circleColors = [UIColor.red]
//        
//        let gradientColors = [UIColor.red.cgColor, UIColor.clear.cgColor] as CFArray
//        let colorLocations: [CGFloat] = [1.0, 0.0]
//        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations)
//        dataSet.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
//        dataSet.drawFilledEnabled = true
//        
//        temperatureGraphView.data = LineChartData(dataSets: [dataSet])
    }
    
    /*
     Removes infoTextView and all it's associated constraints
     Can be used to hide infoTextView when there is no information to display
     */
    fileprivate func hideInfoTextView() -> CGFloat? {
        let constraints = parcelDetailView.constraints
        let infoTextViewConstraint = constraints.first(where: {
            constraint in
            
            if let identifier = constraint.identifier {
                return identifier == "infoTextViewConstraint"
            } else {
                return false
            }
        })
        let infoIconConstraint = constraints.first(where: {
            constraint in
            
            if let identifier = constraint.identifier {
                return identifier == "infoIconConstraint"
            } else {
                return false
            }
        })
        if let infoIconConstraint = infoIconConstraint, let infoTextViewConstraint = infoTextViewConstraint {
            let toContainerViewBottomConstraint = NSLayoutConstraint(item: temperatureGraphView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: parcelDetailView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0)
            
            let containerViewHeightConstraint = parcelDetailView.constraints.first(where: {
                constraint in
                
                if let identifier = constraint.identifier {
                    return identifier == "containerViewHeightConstraint"
                } else {
                    return false
                }
            })
            if let containerViewHeightConstraint = containerViewHeightConstraint {
                let containerViewHeight = containerViewHeightConstraint.constant
                parcelDetailView.removeConstraint(containerViewHeightConstraint)
                let textViewHeight = infoTextView.frame.height
                let tempGraphViewToTextViewSpacing = infoTextViewConstraint.constant
                
                let newContainerHeight = containerViewHeight - (textViewHeight + tempGraphViewToTextViewSpacing)
                
                let newContainerViewHeightConstraint = NSLayoutConstraint(item: parcelDetailView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: newContainerHeight)
                
                temperatureGraphView.removeConstraints([infoIconConstraint, infoTextViewConstraint])
                parcelDetailView.addConstraint(toContainerViewBottomConstraint)
                parcelDetailView.addConstraint(newContainerViewHeightConstraint)
                
                infoIcon.isHidden = true
                infoTextView.isHidden = true
                
                return newContainerHeight
            }
        }
        
        return nil
    }
    
}
