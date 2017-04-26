//
//  QRScanner.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import AVFoundation
import UIKit

class CodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: Properties
    
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    fileprivate var isSensorMACDiscovered: Bool = false
    fileprivate var sensorMACAddress: String?
    fileprivate var isContractIDDiscovered: Bool = false
    fileprivate var contractID: String?
    
    /*
     Determines which codes to scan based on this flag:
     If set 'true', user has to only scan contract ID
     If set 'false', user has to scan contract ID and QR code on the sensor
     */
    var isReceivingParcel: Bool = false
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var infoLabel: UILabel!
    @IBOutlet weak fileprivate var typeOfCodeIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* checking user permissions for the camera */
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch authStatus {
            case .authorized:
                initialize()
            case .denied, .restricted:
                showCameraNotAvailableAlert()
            case .notDetermined:
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {
                    granted in
                
                    DispatchQueue.main.async {
                        [weak self] in
                        
                        if let codeScannerViewController = self {
                            if granted {
                                codeScannerViewController.initialize()
                            } else {
                                codeScannerViewController.showCameraNotAvailableAlert()
                            }
                        }
                    }
                })
        }
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if !metadataObjects.isEmpty {
            let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObject.type == AVMetadataObjectTypeQRCode, !isSensorMACDiscovered && !isReceivingParcel {
                if metadataObject.stringValue != nil && !isSensorMACDiscovered {
                    let scannedHexString = metadataObject.stringValue.removeNonHexSymbols()
                    if isValidMacAddress(scannedHexString) {
                        isSensorMACDiscovered = true
                        sensorMACAddress = scannedHexString
                        if isContractIDDiscovered {
                            performSegue(withIdentifier: "goToParcelCreate", sender: self)
                        } else {
                            UIView.transition(with: infoLabel, duration: 1.0, options: [.curveEaseInOut, .transitionFlipFromRight], animations: {
                                [weak self] in
                                
                                if let codeScannerController = self {
                                    codeScannerController.infoLabel.text = "Please, scan Track&Trace number"
                                }
                                }, completion: nil)
                            UIView.transition(with: typeOfCodeIcon, duration: 1.0, options: [.curveEaseInOut, .transitionFlipFromRight], animations: {
                                [weak self] in
                                
                                if let codeScannerController = self {
                                    codeScannerController.typeOfCodeIcon.image = UIImage(named: "barcode")
                                }
                                }, completion: nil)
                        }
                    }
                }
            } else if metadataObject.type == AVMetadataObjectTypeCode128Code, !isContractIDDiscovered {
                if metadataObject.stringValue != nil && !isContractIDDiscovered {
                    isContractIDDiscovered = true
                    contractID = metadataObject.stringValue
                    
                    if isReceivingParcel {
                        performSegue(withIdentifier: "goToParcelReceive", sender: self)
                    } else {
                        if isSensorMACDiscovered {
                            performSegue(withIdentifier: "goToParcelCreate", sender: self)
                        } else {
                            UIView.transition(with: infoLabel, duration: 1.0, options: [.curveEaseInOut, .transitionFlipFromRight], animations: {
                                [weak self] in
                                
                                if let codeScannerController = self {
                                    codeScannerController.infoLabel.text = "Please, scan QR code on the sensor"
                                }
                            }, completion: nil)
                            UIView.transition(with: typeOfCodeIcon, duration: 1.0, options: [.curveEaseInOut, .transitionFlipFromRight], animations: {
                                [weak self] in
                                
                                if let codeScannerController = self {
                                    codeScannerController.typeOfCodeIcon.image = UIImage(named: "qr_code")
                                }
                            }, completion: nil)
                        }
                    }
                }
            }
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let parcelCreateViewController = segue.destination as? ParcelCreateViewController {
            parcelCreateViewController.sensorMAC = sensorMACAddress
            parcelCreateViewController.tntNumber = contractID
        } else if let parcelReceiveViewController = segue.destination as? ParcelReceiveViewController {
            parcelReceiveViewController.tntNumber = contractID
        }
    }
    
    // MARK: Helper functions
    
    fileprivate func initialize() {
        /* instantiating video capture */
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var captureInput: AVCaptureInput?
        if let captureDevice = captureDevice {
            do {
                captureInput = try AVCaptureDeviceInput(device: captureDevice)
            } catch {
                log("Failed to instantiate AVCaptureInput with \(error.localizedDescription)")
                return
            }
            
            /* adding video camera as input */
            captureSession = AVCaptureSession()
            if let captureSession = captureSession, let captureInput = captureInput {
                captureSession.addInput(captureInput)
            }
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            if let captureSession = captureSession {
                captureSession.addOutput(captureMetadataOutput)
            }
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code]
            
            /* initialize video preview layer */
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            view.bringSubview(toFront: infoLabel)
        }
        
        /* UI configuration */
        
        /* adding gradient backgroud */
        let leftColor = TEMPERATURE_LIGHT_BLUE.cgColor
        let middleColor = ROSE_COLOR.cgColor
        let rightColor = LIGHT_BLUE_COLOR.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [leftColor, middleColor, rightColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        /* adding transparent overlay */
        let overlayPath = UIBezierPath(rect: view.bounds)
        var transparentHole: UIBezierPath!
        if getDeviceScreenSize() == .small {
            transparentHole = UIBezierPath(rect: CGRect(x: 0, y: view.bounds.height/2.0 - 50.0, width: view.bounds.width, height: 200.0))
        } else {
            transparentHole = UIBezierPath(rect: CGRect(x: 0, y: view.bounds.height/2.0 - 100.0, width: view.bounds.width, height: 300.0))
        }
        overlayPath.append(transparentHole)
        overlayPath.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        
        view.layer.addSublayer(fillLayer)
        view.bringSubview(toFront: infoLabel)
        view.bringSubview(toFront: typeOfCodeIcon)
        
        if isReceivingParcel {
            infoLabel.text = "Please, scan Track&Trace number"
            typeOfCodeIcon.image = UIImage(named: "barcode")
        } else {
            infoLabel.text = "Please, scan QR code on the sensor"
            typeOfCodeIcon.image = UIImage(named: "qr_code")
        }
    }
    
    fileprivate func showCameraNotAvailableAlert() {
        let cameraNotAvailableAlertController = UIAlertController(title: "Camera isn't avaialable", message: "Please, set \"Camera\" to \"On\"", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            [weak self]
            _ in
            
            if let codeScannerViewController = self {
                cameraNotAvailableAlertController.dismiss(animated: true, completion: nil)
                _ = codeScannerViewController.navigationController?.popToRootViewController(animated: true)
            }
        })
        let goToSettingsAction = UIAlertAction(title: "Settings", style: .default, handler: {
            _ in
            
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(settingsURL, completionHandler: nil)
            }
        })
        cameraNotAvailableAlertController.addAction(goToSettingsAction)
        cameraNotAvailableAlertController.addAction(cancelAction)
        
        present(cameraNotAvailableAlertController, animated: true, completion: nil)
    }

}
