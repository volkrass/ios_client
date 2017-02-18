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

class ParcelsTableViewController : UITableViewController, CoreDataEnabledController, ServerEnabledController {
    
    // MARK: ServerEnabledController
    
    var serverManager: ServerManager?
    
    // MARK: CoreDataEnabledController
    
    var coreDataManager: CoreDataManager?
    
    // MARK: FoldingCell
    
    fileprivate struct C {
        struct CellHeight {
            static let close: CGFloat = 179.0
            static let open: CGFloat = 488.0
        }
    }
    
    fileprivate var cellHeights: [CGFloat] = []
    
    // MARK: Properties
    
    fileprivate var sentParcels: [Parcel] = []
    fileprivate var receivedParcels: [Parcel] = []
    fileprivate var parcels: [Parcel] = []
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
        set {
            UserDefaults.standard.set(newValue == .sender ? true : false, forKey: "isSenderMode")
        }
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func modeSwitchValueChanged(_ sender: UISwitch) {
        currentMode = sender.isOn ? .receiver : .sender
        navigationItem.title = currentMode.rawValue + " Mode"
        tableView.reloadData()
    }
    
    @IBAction fileprivate func sendButtonDidTouchDown(sender: UIButton) {
        performSegue(withIdentifier: "scanQRcode", sender: self)
    }
    
    @IBAction fileprivate func receiveButtonDidTouchDown(sender: UIButton) {
        performSegue(withIdentifier: "scanQRcode", sender: self)
    }
    
    override func viewDidLoad() {
        guard serverManager != nil else {
            fatalError("ParcelsTableViewController.viewDidLoad(): nil instance of ServerManager")
        }
        guard coreDataManager != nil else {
            fatalError("ParcelsTableViewController.viewDidLoad(): nil instance of CoreDataManager")
        }
        
        fetchParcels()
        
        cellHeights = (0..<50).map { _ in C.CellHeight.close }
        
        tableView.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        
        /* UI settings */
        //tableView.estimatedRowHeight = 120
        
        /* adding 'pull-to-refresh'*/
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Updating parcels...")
        refreshControl!.tintColor = MODUM_LIGHT_BLUE
        refreshControl!.addTarget(self, action: #selector(refreshParcels(_:)), for: UIControlEvents.valueChanged)
        
        /* configuring switch for receiver/sender mode */
        /* off state = sender mode, on state = receiver mode */
        let modeSwitch = UISwitch()
        if currentMode == .sender {
            modeSwitch.setOn(false, animated: false)
        } else {
            modeSwitch.setOn(true, animated: false)
        }
        modeSwitch.onTintColor = MODUM_LIGHT_BLUE
        modeSwitch.backgroundColor = MODUM_DARK_BLUE
        modeSwitch.layer.cornerRadius = 16.0
        modeSwitch.tintColor = MODUM_DARK_BLUE
        modeSwitch.addTarget(self, action: #selector(modeSwitchValueChanged), for: .valueChanged)
        let switchBarButtonItem = UIBarButtonItem(customView: modeSwitch)
        navigationItem.rightBarButtonItem = switchBarButtonItem
        navigationItem.title = currentMode.rawValue + " Mode"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = false
    }
    
    fileprivate func fetchParcels() {
        let parcelFetchRequest = NSFetchRequest<Parcel>(entityName: "Parcel")
        parcelFetchRequest.propertiesToFetch = ["tntNumber", "dateSent", "dateReceived", "senderCompany", "receiverCompany"]
        parcelFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSent", ascending: false)]
        do {
            parcels = try coreDataManager!.viewingContext.fetch(parcelFetchRequest)
            sentParcels = parcels.filter({
                parcel in
                
                return parcel.isSent && !parcel.isReceived
            })
            receivedParcels = parcels.filter({
                parcel in
                
                return parcel.isReceived
            })
        } catch {
            log("Failed to fetch Parcels")
        }
    }
    
    @objc fileprivate func refreshParcels(_ sender: AnyObject) {
        parcels.forEach({
            parcel in
            
            coreDataManager!.viewingContext.delete(parcel)
        })
        if coreDataManager!.viewingContext.hasChanges {
            _ = coreDataManager!.viewingContext.saveRecursively()
        }
        serverManager!.getUserParcels(completionHandler: {
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
    
    // MARK: UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
//        if currentMode == .sender {
//            cellHeights = (0..<sentParcels.count).map { _ in C.CellHeight.close }
//            return sentParcels.count
//        } else {
//            cellHeights = (0..<receivedParcels.count).map { _ in C.CellHeight.close }
//            return receivedParcels.count
//        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let parcelTableViewCell = tableView.dequeueReusableCell(withIdentifier: "parcelCell") as! ParcelTableViewCell
        var parcel: Parcel!
        if currentMode == .sender {
            parcel = sentParcels[indexPath.row]
        } else {
            parcel = receivedParcels[indexPath.row]
        }
//        parcelTableViewCell.tntNumberLabel.text = parcel.tntNumber
//        parcelTableViewCell.sentTimeLabel.text = parcel.dateSent.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
//        if let dateReceived = parcel.dateReceived {
//            parcelTableViewCell.receivedTimeLabel.text = dateReceived.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
//        } else {
//            parcelTableViewCell.receivedTimeLabel.text = "-"
//        }
//        if currentMode == .sender {
//            parcelTableViewCell.companyNameLabel.text = parcel.senderCompany
//        } else {
//            parcelTableViewCell.companyNameLabel.text = parcel.receiverCompany
//        }
//        let parcelStatus = parcel.getStatus()
//        switch parcelStatus {
//            case .inProgress:
//                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_inProgress")
//            case .notWithinTemperatureRange:
//                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_failure")
//            case .successful:
//                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_success")
//            case .undetermined:
//                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_undetermined")
//        }
        return parcelTableViewCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if currentMode == .sender {
//            selectedParcel = sentParcels[indexPath.row]
//        } else {
//            selectedParcel = receivedParcels[indexPath.row]
//        }
//        performSegue(withIdentifier: "showParcelDetail", sender: self)
        guard let foldingCell = tableView.cellForRow(at: indexPath) as? FoldingCell else {
            return
        }
        
        var duration = 0.0
        if cellHeights[indexPath.row] == C.CellHeight.close { // open cell
            cellHeights[indexPath.row] = C.CellHeight.open
            foldingCell.selectedAnimation(true, animated: true, completion: nil)
            duration = 0.5
        } else {// close cell
            cellHeights[indexPath.row] = C.CellHeight.close
            foldingCell.selectedAnimation(false, animated: true, completion: nil)
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
            
            if cellHeights[indexPath.row] == C.CellHeight.close {
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
            titleButton.layer.cornerRadius = 5.0
            
            if currentMode == .sender {
                titleButton.setTitle("SEND", for: .normal)
                //titleButton.backgroundColor = MODUM_LIGHT_BLUE
                titleButton.addTarget(self, action: #selector(sendButtonDidTouchDown(sender:)), for: .touchUpInside)
            } else if currentMode == .receiver {
                titleButton.setTitle("RECEIVE", for: .normal)
                //titleButton.backgroundColor = MODUM_DARK_BLUE
                titleButton.addTarget(self, action: #selector(receiveButtonDidTouchDown(sender:)), for: .touchUpInside)
            } else {
                log("Unknown mode \(currentMode.rawValue)!")
                return nil
            }
            titleButton.backgroundColor = UIColor.orange
            titleButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
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
        if let parcelDetailController = segue.destination as? ParcelDetailTableViewController {
            parcelDetailController.parcel = selectedParcel
        } else if let codeScannerController = segue.destination as? CodeScannerViewController {
            codeScannerController.isReceivingParcel = currentMode == .receiver
        }
    }
    
}
