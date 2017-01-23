//
//  ParcelsViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreData

class ParcelsTableViewController : UITableViewController, NSFetchedResultsControllerDelegate, CoreDataEnabledController, ServerEnabledController {
    
    // MARK: ServerEnabledController
    
    var serverManager: ServerManager?
    
    // MARK: CoreDataEnabledController
    
    var coreDataManager: CoreDataManager?
    
    // MARK: Properties
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<Parcel>!
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
        
        let allParcelsRequest = NSFetchRequest<Parcel>(entityName: "Parcel")
        allParcelsRequest.predicate = NSPredicate(value: true)
        allParcelsRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: allParcelsRequest, managedObjectContext: coreDataManager.viewingContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            fatalError("ParcelsTableViewController.viewDidLoad(): NSFetchedResultsController failed to perform fetch! Error is \(error.localizedDescription)")
        }
        fetchedResultsController.delegate = self
        
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
    
    @objc fileprivate func refreshParcels(_ sender: AnyObject) {
        serverManager!.getUserParcels(completionHandler: {
            [weak self]
            success in
            
            if let parcelsTableViewController = self {
                parcelsTableViewController.refreshControl!.endRefreshing()
                if !success {
                    //TODO: design a view indicating fetch error
                }
            }
        })
    }
    
    // MARK: UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let parcelTableViewCell = tableView.dequeueReusableCell(withIdentifier: "parcelCell") as! ParcelTableViewCell
        let parcel = fetchedResultsController.object(at: indexPath) 
        parcelTableViewCell.tntNumberLabel.text = parcel.tntNumber
        if let dateSent = parcel.dateSent {
            parcelTableViewCell.sentTimeLabel.text = dateSent.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            parcelTableViewCell.sentTimeLabel.text = "-"
        }
        if let dateReceived = parcel.dateReceived {
            parcelTableViewCell.receivedTimeLabel.text = dateReceived.toString(WithDateStyle: .medium, WithTimeStyle: .medium)
        } else {
            parcelTableViewCell.receivedTimeLabel.text = "-"
        }
        return parcelTableViewCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedParcel = fetchedResultsController.object(at: indexPath)
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
        }
    }
    
    // MARK: Helper functions
    
    fileprivate func createModeView(ForMode mode: Mode) -> UIView? {
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let distanceFromBottom: CGFloat = 113.0
        
        let modeView = UIView(frame: CGRect(x: 0, y: screenHeight - distanceFromBottom, width: screenWidth, height: 50))
        //modeView.translatesAutoresizingMaskIntoConstraints = false
        
        /* defining constraints */
//        let leftConstraint = NSLayoutConstraint(item: modeView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: tableView.bounds.width)
//        let rightConstraint = NSLayoutConstraint(item: modeView, attribute: .right, relatedBy: .equal, toItem: tableView, attribute: .right, multiplier: 1.0, constant: 0.0)
//        let bottomConstraint = NSLayoutConstraint(item: modeView, attribute: .bottom, relatedBy: .equal, toItem: tableView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        let titleButton = UIButton(frame: modeView.bounds)
        //titleButton.translatesAutoresizingMaskIntoConstraints = false
        
//        /* defining constraints */
//        let leftButtonConstraint = NSLayoutConstraint(item: titleButton, attribute: .left, relatedBy: .equal, toItem: modeView, attribute: .left, multiplier: 1.0, constant: 0.0)
//        let rightButtonConstraint = NSLayoutConstraint(item: titleButton, attribute: .right, relatedBy: .equal, toItem: modeView, attribute: .right, multiplier: 1.0, constant: 0.0)
//        let bottomButtonConstraint = NSLayoutConstraint(item: titleButton, attribute: .bottom, relatedBy: .equal, toItem: modeView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
//        let topButtonConstraint = NSLayoutConstraint(item: titleButton, attribute: .top, relatedBy: .equal, toItem: modeView, attribute: .top, multiplier: 1.0, constant: 0.0)
        
        if mode == .Sender {
            titleButton.setTitle("SEND", for: .normal)
            titleButton.backgroundColor = UIColor.orange
            titleButton.addTarget(self, action: #selector(sendButtonDidTouchDown(sender:)), for: .touchUpInside)
        } else if mode == .Receiver {
            titleButton.setTitle("RECEIVE", for: .normal)
            titleButton.backgroundColor = MODUM_LIGHT_GRAY
            titleButton.addTarget(self, action: #selector(receiveButtonDidTouchDown(sender:)), for: .touchUpInside)
        } else {
            log("Unknown mode \(mode.rawValue)!")
            return nil
        }
        titleButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)
        titleButton.titleLabel?.textAlignment = .center
        titleButton.setTitleColor(UIColor.white, for: .normal)
        
        modeView.addSubview(titleButton)
        //modeView.addConstraint(widthConstraint)
        //modeView.addConstraints([leftButtonConstraint,rightButtonConstraint,topButtonConstraint,bottomButtonConstraint])
        
        view.addSubview(modeView)
        //view.addConstraints([bottomConstraint])
        
        return modeView
    }
    
}
