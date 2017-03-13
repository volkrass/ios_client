//
//  SettingsTableViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 09.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit

class SettingsViewController : UIViewController {
    
    // MARK: Properties
    
    fileprivate var companyDefaults: CompanyDefaults?
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var infoView: UIView!
    @IBOutlet weak fileprivate var usernameLabel: UILabel!
    @IBOutlet weak fileprivate var companyNameLabel: UILabel!
    
    @IBOutlet weak fileprivate var modeView: UIView!
    @IBOutlet weak fileprivate var modeLabel: UILabel!
    
    @IBOutlet weak fileprivate var logoutView: UIView!
    
    // MARK: Actions
    
    @IBAction fileprivate func modeSwitchButtonTouchUpInside(_ sender: UIButton) {
        let isSenderMode = UserDefaults.standard.bool(forKey: "isSenderMode")
        UserDefaults.standard.set(!isSenderMode, forKey: "isSenderMode")
        if isSenderMode {
            modeLabel.text = "Receiver Mode"
        } else {
            modeLabel.text = "Sender Mode"
        }
    }
    
    @IBAction fileprivate func logoutButtonTouchUpInside(_ sender: UIButton) {
        /* clear UserDefaults */
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "authTokenExpiry")
        
        /* clear CompanyDefaults */
        
        if let loginViewController = storyboard!.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            present(loginViewController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* adding gradient background */
        let leftColor = TEMPERATURE_LIGHT_BLUE.cgColor
        let rightColor = TEMPERATURE_LIGHT_RED.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [leftColor, rightColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        infoView.layer.cornerRadius = 10.0
        modeView.layer.cornerRadius = 10.0
        logoutView.layer.cornerRadius = 10.0
        
        /* navigation bar configuration */
        navigationItem.title = "Settings"
        if let openSansFont = UIFont(name: "OpenSans-Light", size: 20.0) {
            navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : openSansFont]
        }
        if let navigationController = navigationController {
            navigationController.navigationBar.tintColor = UIColor.black
        }
        
        /* filling the content */
        let currentMode = UserDefaults.standard.bool(forKey: "isSenderMode")
        if currentMode {
            modeLabel.text = "Sender Mode"
        } else {
            modeLabel.text = "Receiver Mode"
        }
        
        let cdCompanyDefaultsRecords = CoreDataManager.shared.getAllRecords(ForEntityName: "CDCompanyDefaults")
        if !cdCompanyDefaultsRecords.isEmpty, let cdCompanyDefaults = cdCompanyDefaultsRecords[0] as? CDCompanyDefaults {
            companyDefaults = CompanyDefaults(WithCoreDataObject: cdCompanyDefaults)
            
        }
    }
    
}
