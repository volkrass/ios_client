//
//  SettingsTableViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 09.03.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import UIKit
import Spring

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
        if let springButton = sender as? SpringButton {
            let isSenderMode = UserDefaults.standard.bool(forKey: "isSenderMode")
            UserDefaults.standard.set(!isSenderMode, forKey: "isSenderMode")
            let timer = Timer(timeInterval: 0.7, repeats: false, block: {
                [weak self]
                timer in
                
                timer.invalidate()
                if let settingsController = self {
                    if isSenderMode {
                        settingsController.modeLabel.text = "Receiver Mode"
                    } else {
                        settingsController.modeLabel.text = "Sender Mode"
                    }
                }
            })
            RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
            springButton.animation = "pop"
            springButton.curve = "easeInSine"
            springButton.force = 1.0
            springButton.velocity = 0.7
            springButton.duration = 1.0
            springButton.animate()
        }
    }
    
    @IBAction fileprivate func logoutButtonTouchUpInside(_ sender: UIButton) {
        LoginManager.shared.clear()
        
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
        
        usernameLabel.text = LoginManager.shared.getUsername() ?? "-"
        companyNameLabel.text = LoginManager.shared.getCompanyName() ?? "-"
    }
    
}
