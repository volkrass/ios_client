//
//  ParcelsViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreData
import FoldingCell

class ParcelsTableViewController : UITableViewController {
    
    // MARK: FoldingCell
    
    fileprivate struct CellHeight {
        static let close: CGFloat = 179.0
        static let open: CGFloat = 510.0
    }
    
    fileprivate var cellHeights: [CGFloat] = []
    
    // MARK: Properties
    
    fileprivate var parcels: [Parcel] = [] {
        didSet {
            cellHeights = (0..<parcels.count).map { _ in CellHeight.close }
        }
    }
    
    fileprivate var selectedParcel: Parcel?
    
    /* indicates the mode of the view controller */
    fileprivate enum Mode : String {
        case sender = "Sender"
        case receiver = "Receiver"
    }
    
    fileprivate var currentMode: Mode {
        get {
            if let isSender = UserDefaults.standard.object(forKey: "isSenderMode") as? Bool {
                return isSender ? .sender : .receiver
            } else {
                return .sender
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func statusRefreshButtonTouchUpInside(_ sender: UIButton) {
        
    }
    
    @IBAction fileprivate func sendButtonDidTouchDown(sender: UIButton) {
        performSegue(withIdentifier: "scanQRcode", sender: self)
    }
    
    @IBAction fileprivate func receiveButtonDidTouchDown(sender: UIButton) {
        performSegue(withIdentifier: "scanQRcode", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchParcels()
        
        tableView.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        
        /* adding 'pull-to-refresh'*/
        refreshControl = UIRefreshControl()
        refreshControl!.frame = CGRect(x: refreshControl!.frame.minX, y: refreshControl!.frame.minY, width: 35.0, height: 35.0)
        refreshControl!.attributedTitle = NSAttributedString(string: "Updating parcels...", attributes: [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName : UIFont(name: "OpenSans-Light", size: 17.0) as Any])
        refreshControl!.tintColor = UIColor.white
        refreshControl!.addTarget(self, action: #selector(refreshParcels(_:)), for: UIControlEvents.valueChanged)
        
//        let settingsButton = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(goToSettings))
//        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.title = currentMode.rawValue + " Mode"
        if let openSansFont = UIFont(name: "OpenSans-Light", size: 23.0) {
            navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : openSansFont]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parcels.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let parcelTableViewCell = tableView.dequeueReusableCell(withIdentifier: "parcelCell") as! ParcelTableViewCell
        let parcel = parcels[indexPath.row]
        
        parcelTableViewCell.tntNumberLabel.text = parcel.tntNumber
        parcelTableViewCell.sentTimeLabel.text = parcel.dateSent.toString(WithDateStyle: .short, WithTimeStyle: .short)
        if let dateReceived = parcel.dateReceived {
            parcelTableViewCell.receivedTimeLabel.text = dateReceived.toString(WithDateStyle: .short, WithTimeStyle: .short)
        } else {
            parcelTableViewCell.receivedTimeLabel.text = "-"
        }
        if currentMode == .sender {
            parcelTableViewCell.companyNameLabel.text = parcel.senderCompany
        } else {
            parcelTableViewCell.companyNameLabel.text = parcel.receiverCompany
        }
        let parcelStatus = parcel.getStatus()
        switch parcelStatus {
            case .inProgress:
                parcelTableViewCell.statusView.backgroundColor = STATUS_ORANGE
            case .notWithinTemperatureRange:
                parcelTableViewCell.statusView.backgroundColor = STATUS_RED
            case .successful:
                parcelTableViewCell.statusView.backgroundColor = STATUS_GREEN
            case .undetermined:
                parcelTableViewCell.statusView.backgroundColor = UIColor.gray
        }
        
        return parcelTableViewCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let parcelCell = tableView.cellForRow(at: indexPath) as? ParcelTableViewCell else {
            return
        }
        
        let parcel = parcels[indexPath.row]
        
        /* filling in parcel detail information */
        let parcelStatus = parcel.getStatus()
        switch parcelStatus {
            case .inProgress:
                parcelCell.detailStatusView.backgroundColor = STATUS_ORANGE
            case .notWithinTemperatureRange:
                parcelCell.detailStatusView.backgroundColor = STATUS_RED
            case .successful:
                parcelCell.detailStatusView.backgroundColor = STATUS_GREEN
            case .undetermined:
                parcelCell.detailStatusView.backgroundColor = UIColor.gray
        }
        parcelCell.detailTntNumberLabel.text = parcel.tntNumber
        parcelCell.detailSentTimeLabel.text = parcel.dateSent.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        if let dateReceived = parcel.dateReceived {
            parcelCell.detailReceivedTimeLabel.text = dateReceived.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            parcelCell.detailReceivedTimeLabel.text = "-"
        }
        parcelCell.detailSenderCompanyLabel.text = parcel.senderCompany
        parcelCell.detailReceiverCompanyLabel.text = parcel.receiverCompany.isEmpty ? "-" : parcel.receiverCompany
        parcelCell.detailTempMinLabel.text = String(parcel.minTemp) + "℃"
        parcelCell.detailTempMaxLabel.text = String(parcel.maxTemp) + "℃"
        parcelCell.statusImageView.image = UIImage(named: "status_unknown")
        
        var newParcelDetailCellHeight: CGFloat? = nil
        if let additionalInfo = parcel.additionalInfo, !additionalInfo.isEmpty {
            parcelCell.infoTextView.text = additionalInfo
        } else {
            newParcelDetailCellHeight = parcelCell.hideInfoTextView()
        }
        parcelCell.displayMeasurements(measurements: [], minTemp: Double(parcel.minTemp), maxTemp: Double(parcel.maxTemp))
        
        var duration = 0.0
        if cellHeights[indexPath.row] == CellHeight.close {
            if let additionalInfo = parcel.additionalInfo, !additionalInfo.isEmpty {
                cellHeights[indexPath.row] = CellHeight.open
            } else {
                if let newParcelDetailCellHeight = newParcelDetailCellHeight {
                    cellHeights[indexPath.row] = newParcelDetailCellHeight
                }
            }
            parcelCell.selectedAnimation(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = CellHeight.close
            parcelCell.selectedAnimation(false, animated: true, completion: nil)
            duration = 0.8
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { _ in
            tableView.beginUpdates()
            tableView.endUpdates()
        }, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let foldingCell = cell as? ParcelTableViewCell {
            
            foldingCell.backgroundColor = UIColor.clear
            
            if cellHeights[indexPath.row] == CellHeight.close {
                foldingCell.selectedAnimation(false, animated: false, completion:nil)
            } else {
                foldingCell.selectedAnimation(true, animated: false, completion:nil)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let modeView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 50))
            let titleButton = UIButton(frame: CGRect(x: modeView.bounds.width / 4.0, y: 7.5, width: modeView.bounds.width / 2.0, height: modeView.bounds.height - 15.0))
            titleButton.layer.cornerRadius = 10.0
            
            if currentMode == .sender {
                titleButton.setTitle("SEND", for: .normal)
                titleButton.addTarget(self, action: #selector(sendButtonDidTouchDown(sender:)), for: .touchUpInside)
            } else if currentMode == .receiver {
                titleButton.setTitle("RECEIVE", for: .normal)
                titleButton.addTarget(self, action: #selector(receiveButtonDidTouchDown(sender:)), for: .touchUpInside)
            } else {
                log("Unknown mode \(currentMode.rawValue)!")
                return nil
            }
            titleButton.backgroundColor = UIColor.orange
            titleButton.titleLabel?.font = UIFont(name: "OpenSans-Bold", size: 16.0)
            titleButton.titleLabel?.textAlignment = .center
            titleButton.setTitleColor(UIColor.white, for: .normal)
            
            modeView.addSubview(titleButton)
            
            return modeView
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 50.0
        } else {
            return 0.0
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let codeScannerController = segue.destination as? CodeScannerViewController {
            codeScannerController.isReceivingParcel = currentMode == .receiver
        }
    }
    
    // MARK: Helper functions
    
    @objc fileprivate func goToSettings() {
        performSegue(withIdentifier: "goToSettings", sender: self)
    }
    
    fileprivate func fetchParcels() {
        let parcelFetchRequest = NSFetchRequest<Parcel>(entityName: "Parcel")
        if currentMode == .sender {
            parcelFetchRequest.predicate = NSPredicate(format: "isSent = %@ AND isReceived = %@", NSNumber(booleanLiteral: true), NSNumber(booleanLiteral: false))
        } else {
            parcelFetchRequest.predicate = NSPredicate(format: "isReceived = %@", NSNumber(booleanLiteral: true))
        }
        parcelFetchRequest.propertiesToFetch = ["tntNumber", "dateSent", "dateReceived", "senderCompany", "receiverCompany", "isReceived", "isSent", "isSuccess", "isFailed"]
        parcelFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSent", ascending: false)]
        do {
            parcels = try CoreDataManager.shared.viewingContext.fetch(parcelFetchRequest)
        } catch {
             //TODO: design a view indicating fetch error
        }
    }
    
    @objc fileprivate func refreshParcels(_ sender: AnyObject) {
        parcels.forEach({
            parcel in
            
            CoreDataManager.shared.viewingContext.delete(parcel)
        })
        if CoreDataManager.shared.viewingContext.hasChanges {
            _ = CoreDataManager.shared.viewingContext.saveRecursively()
        }
        ServerManager.shared.getUserParcels(completionHandler: {
            [weak self]
            success in
            
            if let parcelsTableViewController = self {
                parcelsTableViewController.refreshControl!.endRefreshing()
                if !success {
                    //TODO: design a view indicating fetch error
                } else {
                    parcelsTableViewController.fetchParcels()
                    parcelsTableViewController.tableView.reloadData()
                }
            }
        })
    }
    
}
