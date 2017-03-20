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
        static let open: CGFloat = 575.0
    }
    
    fileprivate var cellHeights: [CGFloat] = []
    
    // MARK: Properties
    
    fileprivate var parcels: [Parcel] = [] {
        didSet {
            cellHeights = (0..<parcels.count).map { _ in CellHeight.close }
        }
    }
    
    fileprivate var selectedParcel: Parcel?
    
    fileprivate var currentMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isSenderMode")
        }
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func sendButtonDidTouchDown(sender: UIButton) {
        performSegue(withIdentifier: "scanQRcode", sender: self)
    }
    
    @IBAction fileprivate func receiveButtonDidTouchDown(sender: UIButton) {
        performSegue(withIdentifier: "scanQRcode", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchParcels()
        
        /* adding 'pull-to-refresh'*/
        refreshControl = UIRefreshControl()
        //refreshControl?.backgroundColor = UIColor.clear
        refreshControl!.frame = CGRect(x: refreshControl!.frame.minX, y: refreshControl!.frame.minY, width: 35.0, height: 35.0)
        refreshControl!.attributedTitle = NSAttributedString(string: "Updating parcels...", attributes: [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName : UIFont(name: "OpenSans-Light", size: 17.0) as Any])
        refreshControl!.tintColor = UIColor.white
        refreshControl!.addTarget(self, action: #selector(ParcelsTableViewController.fetchParcels), for: UIControlEvents.valueChanged)
        
        /* adding gradient background */
        let leftColor = TEMPERATURE_LIGHT_BLUE.cgColor
        let rightColor = TEMPERATURE_LIGHT_RED.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = tableView.bounds
        gradientLayer.colors = [leftColor, rightColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        let backgroundView = UIView(frame: tableView.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        tableView.backgroundView = backgroundView
        
        let settingsImage = UIImage(named: "settings")
        let settingsButton = UIButton(type: .custom)
        if let settingsImage = settingsImage {
            settingsButton.frame = CGRect(x: 0, y: 0, width: settingsImage.size.width-10.0, height: settingsImage.size.height-10.0)
            settingsButton.setBackgroundImage(settingsImage, for: .normal)
            settingsButton.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
            let settingsBarButton = UIBarButtonItem(customView: settingsButton)
            navigationItem.rightBarButtonItem = settingsBarButton
            //navigationItem.rightBarButtonItem!.isEnabled = false
        }
        
        if let openSansFont = UIFont(name: "OpenSans-Light", size: 20.0) {
            navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : openSansFont]
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = false
        if currentMode {
            navigationItem.title = "Sender Mode"
        } else {
            navigationItem.title = "Receiver Mode"
        }
        tableView.reloadInputViews()
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
        if let dateSent = parcel.dateSent {
            parcelTableViewCell.sentTimeLabel.text = dateSent.toString(WithDateStyle: .short, WithTimeStyle: .short)
        } else {
            parcelTableViewCell.sentTimeLabel.text = "-"
        }
        if let dateReceived = parcel.dateReceived {
            parcelTableViewCell.receivedTimeLabel.text = dateReceived.toString(WithDateStyle: .short, WithTimeStyle: .short)
        } else {
            parcelTableViewCell.receivedTimeLabel.text = "-"
        }
        if currentMode {
            parcelTableViewCell.companyNameLabel.text = parcel.senderCompany
        } else {
            parcelTableViewCell.companyNameLabel.text = parcel.receiverCompany
        }
        if let parcelStatus = parcel.parcelStatus {
            switch parcelStatus {
            case .inProgress:
                parcelTableViewCell.statusView.backgroundColor = STATUS_ORANGE
            case .notWithinTemperatureRange:
                parcelTableViewCell.statusView.backgroundColor = STATUS_RED
            case .successful:
                parcelTableViewCell.statusView.backgroundColor = STATUS_GREEN
            case .undetermined:
                parcelTableViewCell.statusView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
            }
        } else {
            parcelTableViewCell.statusView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        }
        
        return parcelTableViewCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let parcelCell = tableView.cellForRow(at: indexPath) as? ParcelTableViewCell else {
            return
        }
        
        let parcel = parcels[indexPath.row]
        
        var duration = 0.0
        if cellHeights[indexPath.row] == CellHeight.close {
            let newParcelDetailCellHeight = parcelCell.fill(FromParcel: parcel)
            cellHeights[indexPath.row] = newParcelDetailCellHeight
            parcelCell.selectedAnimation(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = CellHeight.close
            parcelCell.resetTemperatureGraphView()
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
            
            if currentMode {
                titleButton.setTitle("SEND", for: .normal)
                titleButton.addTarget(self, action: #selector(sendButtonDidTouchDown(sender:)), for: .touchUpInside)
            } else {
                titleButton.setTitle("RECEIVE", for: .normal)
                titleButton.addTarget(self, action: #selector(receiveButtonDidTouchDown(sender:)), for: .touchUpInside)
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
            codeScannerController.isReceivingParcel = !currentMode
        }
    }
    
    // MARK: Helper functions
    
    @objc fileprivate func goToSettings() {
        performSegue(withIdentifier: "goToSettings", sender: self)
    }
    
    /* Fetches existing Parcel objects from CoreData, if server call fails */
    fileprivate func fetchStoredParcels() {
        let parcelFetchRequest = NSFetchRequest<CDParcel>(entityName: "CDParcel")
        parcelFetchRequest.predicate = NSPredicate(value: true)
        parcelFetchRequest.propertiesToFetch = ["tntNumber", "dateSent", "dateReceived", "senderCompany", "receiverCompany", "isReceived", "isSent", "isSuccess", "isFailed"]
        parcelFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSent", ascending: false)]
        do {
            let coreDataParcels = try CoreDataManager.shared.viewingContext.fetch(parcelFetchRequest)
            //parcels = coreDataParcels.map{ $0.}
        } catch {
             //TODO: design a view indicating fetch error
        }
    }
    
    /* Queries server to return list of Parcels */
    @objc fileprivate func fetchParcels() {
        ServerManager.shared.getUserParcels(completionHandler: {
            [weak self]
            error, parcels in
            
            if let parcelsTableViewController = self {
                parcelsTableViewController.refreshControl!.endRefreshing()
                if let error = error {
                    //TODO: design a view indicating fetch error
                } else {
                    if let parcels = parcels {
                        parcelsTableViewController.parcels = parcels
                        parcelsTableViewController.tableView.reloadData()
                    }
                }
            }
        })
    }
    
}
