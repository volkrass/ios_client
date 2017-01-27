//
//  ParcelsViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreData

class ParcelsTableViewController : UITableViewController, CoreDataEnabledController, ServerEnabledController {
    
    // MARK: ServerEnabledController
    
    var serverManager: ServerManager?
    
    // MARK: CoreDataEnabledController
    
    var coreDataManager: CoreDataManager?
    
    // MARK: Properties
    
    //fileprivate var fetchedResultsController: NSFetchedResultsController<Parcel>!
    fileprivate var parcels: [Parcel] = []
    fileprivate var selectedParcel: Parcel?
    
    /* indicates the mode of the view controller */
    fileprivate enum Mode : String {
        case Sender = "Sender"
        case Receiver = "Receiver"
    }
    fileprivate var currentMode: Mode = .Sender
    
    /* view indicating which mode is user currently in(sender/receiver) */
    fileprivate var modeView: UIView?
    
    // MARK: Actions
    
    @IBAction fileprivate func modeSwitchValueChanged(_ sender: UISwitch) {
        currentMode = sender.isOn ? .Receiver : .Sender
        navigationItem.title = currentMode.rawValue + " Mode"
        if let modeView = modeView {
            modeView.removeFromSuperview()
        }
        modeView = createModeView(ForMode: currentMode)
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
        guard let coreDataManager = coreDataManager else {
            fatalError("ParcelsTableViewController.viewDidLoad(): nil instance of CoreDataManager")
        }
        
        fetchParcels()
        
        /* UI settings */
        tableView.estimatedRowHeight = 120
        
        /* adding 'pull-to-refresh'*/
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Updating parcels...")
        refreshControl!.tintColor = MODUM_LIGHT_BLUE
        refreshControl!.addTarget(self, action: #selector(refreshParcels(_:)), for: UIControlEvents.valueChanged)
        
        /* create a bottom view for button */
        modeView = createModeView(ForMode: currentMode)
        
        /* configuring switch for receiver/sender mode */
        /* off state = sender mode, on state = receiver mode */
        let modeSwitch = UISwitch()
        modeSwitch.onTintColor = MODUM_LIGHT_BLUE
        modeSwitch.backgroundColor = MODUM_DARK_BLUE
        modeSwitch.layer.cornerRadius = 16.0
        modeSwitch.tintColor = MODUM_DARK_BLUE
        modeSwitch.addTarget(self, action: #selector(modeSwitchValueChanged), for: .valueChanged)
        let switchBarButtonItem = UIBarButtonItem(customView: modeSwitch)
        navigationItem.rightBarButtonItem = switchBarButtonItem
        navigationItem.title = currentMode.rawValue + " Mode"
    }
    
    fileprivate func fetchParcels() {
        let parcelFetchRequest = NSFetchRequest<Parcel>(entityName: "Parcel")
        parcelFetchRequest.propertiesToFetch = ["tntNumber", "dateSent", "dateReceived", "senderCompany", "receiverCompany"]
        parcelFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSent", ascending: false)]
        do {
            parcels = try coreDataManager!.viewingContext.fetch(parcelFetchRequest)
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
        return parcels.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let parcelTableViewCell = tableView.dequeueReusableCell(withIdentifier: "parcelCell") as! ParcelTableViewCell
        let parcel = parcels[indexPath.row]
        parcelTableViewCell.tntNumberLabel.text = parcel.tntNumber
        parcelTableViewCell.sentTimeLabel.text = parcel.dateSent.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        if let dateReceived = parcel.dateReceived {
            parcelTableViewCell.receivedTimeLabel.text = dateReceived.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            parcelTableViewCell.receivedTimeLabel.text = "-"
        }
        if currentMode == .Sender {
            parcelTableViewCell.companyNameLabel.text = parcel.senderCompany
        } else {
            parcelTableViewCell.companyNameLabel.text = parcel.receiverCompany
        }
        let parcelStatus = parcel.getStatus()
        switch parcelStatus {
            case .inProgress:
                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_inProgress")
            case .notWithinTemperatureRange:
                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_failure")
            case .successful:
                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_success")
            case .undetermined:
                parcelTableViewCell.statusIconImageView.image = UIImage(named: "status_undetermined")
        }
        return parcelTableViewCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedParcel = parcels[indexPath.row]
        performSegue(withIdentifier: "showParcelDetail", sender: self)
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let modeView = modeView {
            var newFrame = modeView.frame
            newFrame.origin.x = 0;
            newFrame.origin.y = tableView.contentOffset.y + tableView.bounds.height - modeView.bounds.height;
            modeView.frame = newFrame;
            tableView.bringSubview(toFront: modeView)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let parcelDetailController = segue.destination as? ParcelDetailTableViewController {
            parcelDetailController.parcel = selectedParcel
        } else if let codeScannerController = segue.destination as? CodeScannerViewController {
            codeScannerController.isReceivingParcel = currentMode == .Receiver
        }
    }
    
    // MARK: Helper functions
    
    fileprivate func createModeView(ForMode mode: Mode) -> UIView? {
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let distanceFromBottom: CGFloat = 113.0
        
        let modeView = UIView(frame: CGRect(x: 0, y: screenHeight - distanceFromBottom, width: screenWidth, height: 50))
        
        let titleButton = UIButton(frame: modeView.bounds)
        
        if mode == .Sender {
            titleButton.setTitle("SEND", for: .normal)
            titleButton.backgroundColor = MODUM_LIGHT_BLUE
            titleButton.addTarget(self, action: #selector(sendButtonDidTouchDown(sender:)), for: .touchUpInside)
        } else if mode == .Receiver {
            titleButton.setTitle("RECEIVE", for: .normal)
            titleButton.backgroundColor = MODUM_DARK_BLUE
            titleButton.addTarget(self, action: #selector(receiveButtonDidTouchDown(sender:)), for: .touchUpInside)
        } else {
            log("Unknown mode \(mode.rawValue)!")
            return nil
        }
        titleButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
        titleButton.titleLabel?.textAlignment = .center
        titleButton.setTitleColor(UIColor.white, for: .normal)
        
        modeView.addSubview(titleButton)
        view.addSubview(modeView)
        
        return modeView
    }
    
}
