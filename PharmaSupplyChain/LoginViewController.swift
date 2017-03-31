//
//  ViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var loginView: UIView!
    @IBOutlet weak fileprivate var usernameTextField: UITextField!
    @IBOutlet weak fileprivate var separatorLine: UIView!
    @IBOutlet weak fileprivate var passwordTextField: UITextField!
    
    @IBOutlet weak fileprivate var loginErrorLabel: UILabel!
    
    @IBOutlet weak fileprivate var rememberMeSwitch: UISwitch!
    
    // MARK: Actions
    
    @IBAction fileprivate func loginButtonDidTouchDown(_ sender: UIButton) {
        loginErrorLabel.text = ""
        
        guard !usernameTextField.text!.isEmpty else {
            loginErrorLabel.text = "Please, enter your username"
            return
        }
        
        guard !passwordTextField.text!.isEmpty else {
            loginErrorLabel.text = "Please, enter your password"
            return
        }
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        ServerManager.shared.login(username: username, password: password, completionHandler: {
            [weak self]
            error, response in
            
            if let loginViewController = self {
                /* Error when authenticating */
                if let error = error {
                    loginViewController.loginErrorLabel.text = error.message
                } else if let response = response {
                    /* store user credentials */
                    LoginManager.shared.storeUser(username: username, password: password, response: response, rememberMe: loginViewController.rememberMeSwitch.isOn)
                    
                    /* Retrieving company defaults on login and persist them in CoreData */
                    ServerManager.shared.getCompanyDefaults(completionHandler: {
                        [weak self]
                        error, companyDefaults in
                        
                        if let loginViewController = self {
                            if let error = error {
                                log("Error retrieving company defaults: \(error.message)")
                                loginViewController.loginErrorLabel.text = "Failed to login! Please, try again!"
                            } else {
                                if let companyDefaults = companyDefaults {
                                    loginViewController.performSegue(withIdentifier: "showParcels", sender: loginViewController)
                                    log("Successfully retrieve company defaults!")
                                    CoreDataManager.shared.performBackgroundTask(WithBlock: {
                                        backgroundContext in
                                        
                                        let existingRecords = CoreDataManager.getAllRecords(InContext: backgroundContext, ForEntityName: "CDCompanyDefaults")
                                        existingRecords.forEach({
                                            existingRecord in
                                            
                                            backgroundContext.delete(existingRecord as! NSManagedObject)
                                        })
                                        
                                        let cdCompanyDefaults = NSEntityDescription.insertNewObject(forEntityName: "CDCompanyDefaults", into: backgroundContext) as! CDCompanyDefaults
                                        companyDefaults.toCoreDataObject(object: cdCompanyDefaults)
                                        
                                        CoreDataManager.shared.saveLocally(managedContext: backgroundContext)
                                    })
                                }
                            }
                        }
                    })
                }
            }
        })
    }
    
    @IBAction fileprivate func usernameTextFieldEditingDidBegin(_ sender: UITextField) {
        separatorLine.backgroundColor = MODUM_LIGHT_BLUE
    }
    
    @IBAction fileprivate func usernameTextFieldEditingChanged(_ sender: UITextField) {
        loginErrorLabel.text = ""
    }
    
    @IBAction fileprivate func usernameTextFieldEditingDidEnd(_ sender: UITextField) {
        separatorLine.backgroundColor = UIColor.lightGray
    }
    
    @IBAction fileprivate func passwordTextFieldEditingDidBegin(_ sender: UITextField) {
        separatorLine.backgroundColor = MODUM_LIGHT_BLUE
    }
    
    @IBAction fileprivate func passwordTextFieldEditingChanged(_ sender: UITextField) {
        loginErrorLabel.text = ""
    }
    
    @IBAction fileprivate func passwordTextFieldEditingDidEnd(_ sender: UITextField) {
        separatorLine.backgroundColor = UIColor.lightGray
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* adding gradient background */
        let leftColor = TEMPERATURE_LIGHT_BLUE.cgColor
        let middleColor = ROSE_COLOR.cgColor
        let rightColor = LIGHT_BLUE_COLOR.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [leftColor, middleColor, rightColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        /* making views rounded */
        loginView.layer.cornerRadius = 10.0
        loginView.layer.masksToBounds = true
        
        /* configure gesture recognizer for keyboard dismissing */
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: Helper functions
    
    @objc fileprivate func hideKeyboard() {
        view.endEditing(true)
    }
    
}
