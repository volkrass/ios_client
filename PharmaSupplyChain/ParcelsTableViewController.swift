//
//  ParcelsViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreData
import Google

class ParcelsTableViewController : UITableViewController, NSFetchedResultsControllerDelegate, CoreDataEnabledController {
    
    // MARK: CoreDataEnabledController
    
    var coreDataManager: CoreDataManager?
    
    // MARK: Properties
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<Parcel>!
    
    override func viewDidLoad() {
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
        tableView.estimatedRowHeight = 150
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* Google Analytics setup */
        let tracker = GAI.sharedInstance().defaultTracker
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: "ParcelsTableView")
            
            let builder = GAIDictionaryBuilder.createScreenView()
            if let builder = builder {
                tracker.send(builder.build() as [NSObject : AnyObject])
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        parcelTableViewCell.parcelTitleLabel.text = parcel.tntNumber
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
        
    }
    
}
