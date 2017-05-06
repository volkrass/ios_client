//
//  AppDelegate.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 25.10.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import UXCam
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        /* clear keychain if app was de-installed and installed again */
        if UserDefaults.standard.object(forKey: "FirstLaunch") == nil {
            LoginManager.shared.clear()
            UserDefaults.standard.set(true, forKey: "FirstLaunch")
        }
        
        /* setting up analytics */
        FIRApp.configure()
        UXCam.start(withKey: "4e331aa53d215bd")
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        window = UIWindow(frame: UIScreen.main.bounds)
        if let window = window {
            window.rootViewController = storyboard.instantiateViewController(withIdentifier: "RootViewControllerID") as? RootViewController
        }
        
        /* request permission to send notifications */
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.getNotificationSettings(completionHandler: {
            [unowned notificationCenter]
            settings in
            
            if settings.authorizationStatus == .notDetermined {
                notificationCenter.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {
                    success, error in
                    
                    if !success {
                        log("Notifications are disabled for the application")
                    }
                    if let error = error {
                        log("Error requesting permission to send notifications: \(error.localizedDescription)")
                    }
                })
            }
        })
        
        /* resume pending uploads */
        RecurrentUploader.shared.resumeDownloads()
        
        /* re-login user every time he starts the app */
        if let username = LoginManager.shared.getUsername(), let password = LoginManager.shared.getPassword() {
            ServerManager.shared.login(username: username, password: password, completionHandler: {
                [weak self]
                error, response in
                
                if let appDelegate = self {
                    if let error = error {
                        log("Error during login! Error is: \(error.message ?? "")")
                        /* if there is no internet and token isn't yet expired, present parcels screen */
                        
                        if let authTokenExpiry = LoginManager.shared.getAuthTokenExpiry(), authTokenExpiry > Date(), error == ServerError.noInternet {
                            if let parcelsNavigationController = storyboard.instantiateViewController(withIdentifier: "ParcelsNavigationController") as? UINavigationController {
                                appDelegate.window!.rootViewController = parcelsNavigationController
                            }
                        } else {
                            if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                                appDelegate.window!.rootViewController = loginViewController
                            }
                        }
                    } else if let response = response {
                        /* store user credentials */
                        LoginManager.shared.storeUser(username: username, password: password, response: response, rememberMe: true)
                        
                        /* Retrieving company defaults on login and persist them in CoreData */
                        ServerManager.shared.getCompanyDefaults(completionHandler: {
                            [weak self]
                            error, companyDefaults in
                            
                            if let appDelegate = self {
                                if let error = error {
                                    log("Error retrieving company defaults: \(error.message ?? "")")
                                    if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                                        appDelegate.window!.rootViewController = loginViewController
                                    }
                                } else {
                                    if let companyDefaults = companyDefaults {
                                        if let parcelsNavigationController = storyboard.instantiateViewController(withIdentifier: "ParcelsNavigationController") as? UINavigationController {
                                            appDelegate.window!.rootViewController = parcelsNavigationController
                                        }
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
        } else {
            if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                window!.rootViewController = loginViewController
            }
        }
        
        window!.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
    // MARK: UNUserNotificationCenterDelegate
    
    /* called when deciding which options to use when notification is presented at foreground */
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

}

