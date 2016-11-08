//
//  ViewController.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import QuartzCore

class LoginViewController: UIViewController, ServerEnabledController, CoreDataEnabledController {
    
    // MARK: CoreDataEnabledController
    
    var coreDataManager: CoreDataManager?
    
    // MARK: ServerEnabledController
    
    var serverManager: ServerManager?
    
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
        
        if let loginCredentials = LoginCredentials(username: username, password: password) {
            serverManager!.authenticateUser(WithCredentials: loginCredentials, completionHandler: {
                [weak self]
                error in
                
                if let loginViewController = self {
                    /* Successful authentication */
                    if let error = error {
                        switch error {
                            case AuthenticationError.InvalidCredentials:
                                loginViewController.loginErrorLabel.text = "Invalid credentials. Please, try again!"
                                loginViewController.usernameTextField.text = ""
                                loginViewController.passwordTextField.text = ""
                                return
                            case AuthenticationError.OtherProblem:
                                loginViewController.loginErrorLabel.text = "An error occured while logging in. Please, try again!"
                                return
                        }
                    } else {
                        loginViewController.serverManager!.getUserParcels {
                            [weak loginViewController]
                            success in
                            
                            if let loginViewController = loginViewController {
                                loginViewController.performSegue(withIdentifier: "showParcels", sender: loginViewController)
                            }
                        }
                    }
                }
            })
        } else {
            loginErrorLabel.text = "Invalid credentials. Please, try again!"
            usernameTextField.text = ""
            passwordTextField.text = ""
        }
    }
    
    @IBAction fileprivate func usernameTextFieldEditingChanged(_ sender: UITextField) {
        usernameErrorLabel.text = ""
    }
    
    @IBAction fileprivate func passwordTextFieldEditingChanged(_ sender: UITextField) {
        passwordErrorLabel.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard coreDataManager != nil else {
            fatalError("LoginViewController.viewDidLoad(): nil instance of CoreDataManager")
        }
        guard serverManager != nil else {
            fatalError("LoginViewController.viewDidLoad(): nil instance of ServerManager")
        }
        
        /* setting UITextField visual properties */
        usernameTextField.layer.masksToBounds = true
        usernameTextField.layer.borderWidth = 1.0
        usernameTextField.layer.cornerRadius = 3.0
        usernameTextField.layer.borderColor = view.tintColor.cgColor
        passwordTextField.layer.masksToBounds = true
        passwordTextField.layer.borderWidth = 1.0
        passwordTextField.layer.cornerRadius = 3.0
        passwordTextField.layer.borderColor = view.tintColor.cgColor
        
        /* configure gesture recognizer for keyboard dismissing */
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func hideKeyboard() {
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController, var coreDataController = navController.childViewControllers[0] as? CoreDataEnabledController {
            coreDataController.coreDataManager = coreDataManager
        }
    }
    
}
