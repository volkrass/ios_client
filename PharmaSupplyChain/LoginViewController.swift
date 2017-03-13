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
    
    @IBOutlet weak fileprivate var usernameTextField: UITextField!
    @IBOutlet weak fileprivate var usernameErrorLabel: UILabel!
    @IBOutlet weak fileprivate var passwordTextField: UITextField!
    @IBOutlet weak fileprivate var passwordErrorLabel: UILabel!
    @IBOutlet weak fileprivate var loginButton: UIButton!
    @IBOutlet weak fileprivate var loginErrorLabel: UILabel!
    
    // MARK: Actions
    
    @IBAction fileprivate func loginButtonDidTouchDown(_ sender: UIButton) {
        loginErrorLabel.text = ""
        
        guard !usernameTextField.text!.isEmpty else {
            usernameErrorLabel.text = "Please, enter your username"
            return
        }
        
        guard !passwordTextField.text!.isEmpty else {
            passwordErrorLabel.text = "Please, enter your password"
            return
        }
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        guard username.characters.count >= 3 else {
            loginErrorLabel.text = "Username is too short"
            return
        }
        
        guard password.characters.count >= 3 else {
            loginErrorLabel.text = "Password is too short"
            return
        }
        
        ServerManager.shared.login(username: username, password: password, completionHandler: {
            [weak self]
            error, _ in
            
            if let loginViewController = self {
                /* Error when authenticating */
                if let error = error {
                    loginViewController.loginErrorLabel.text = error.message
                } else {
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
    
    @IBAction fileprivate func usernameTextFieldEditingChanged(_ sender: UITextField) {
        usernameErrorLabel.text = ""
    }
    
    @IBAction fileprivate func passwordTextFieldEditingChanged(_ sender: UITextField) {
        passwordErrorLabel.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //view.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        
        /* setting UITextField visual properties */
        usernameTextField.layer.masksToBounds = true
        usernameTextField.layer.borderWidth = 1.0
        usernameTextField.layer.cornerRadius = 10.0
        usernameTextField.layer.borderColor = view.tintColor.cgColor
        passwordTextField.layer.masksToBounds = true
        passwordTextField.layer.borderWidth = 1.0
        passwordTextField.layer.cornerRadius = 10.0
        passwordTextField.layer.borderColor = view.tintColor.cgColor
        
        /* configure gesture recognizer for keyboard dismissing */
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    func hideKeyboard() {
        view.endEditing(true)
    }
    
}
