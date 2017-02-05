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
    fileprivate var scannedCodeFrameView: UIView?
    
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
        
        if metadataObjects == nil || metadataObjects.isEmpty {
            scannedCodeFrameView?.frame = CGRect.zero
            return
        }
        
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObject.type == AVMetadataObjectTypeQRCode, let videoPreviewLayer = videoPreviewLayer, !isSensorMACDiscovered && !isReceivingParcel {
            let qrCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObject as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            scannedCodeFrameView?.frame = qrCodeObject.bounds
            
            if metadataObject.stringValue != nil && !isSensorMACDiscovered {
                infoLabel.text = metadataObject.stringValue
                let scannedHexString = metadataObject.stringValue.removeNonHexSymbols()
                if isValidMacAddress(scannedHexString) {
                    isSensorMACDiscovered = true
                    sensorMACAddress = scannedHexString
                    infoLabel.backgroundColor = UIColor.green
                    if isContractIDDiscovered {
                        performSegue(withIdentifier: "goToSensorConnect", sender: self)
                    } else {
                        let dispatchTime = DispatchTime.now() + 0.5
                        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                            [weak self] in
                            
                            if let codeScannerViewController = self {
                                codeScannerViewController.scannedCodeFrameView?.frame = CGRect.zero
                                codeScannerViewController.infoLabel.text = "Please, scan shipment ID code!"
                                codeScannerViewController.infoLabel.backgroundColor = MODUM_LIGHT_GRAY
                            }
                        })
                    }
                }
            }
        } else if metadataObject.type == AVMetadataObjectTypeCode128Code, let videoPreviewLayer = videoPreviewLayer, !isContractIDDiscovered {
            let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObject as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            scannedCodeFrameView?.frame = barCodeObject.bounds
            
            if metadataObject.stringValue != nil && !isContractIDDiscovered {
                infoLabel.text = metadataObject.stringValue
                /* TODO: add validation code for contract ID */
                isContractIDDiscovered = true
                contractID = metadataObject.stringValue
                infoLabel.backgroundColor = UIColor.green
                
                if isReceivingParcel || (!isReceivingParcel && isSensorMACDiscovered) {
                    performSegue(withIdentifier: "goToSensorConnect", sender: self)
                } else {
                    let dispatchTime = DispatchTime.now() + 0.5
                    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                        [weak self] in
                        
                        if let codeScannerViewController = self {
                            codeScannerViewController.scannedCodeFrameView?.frame = CGRect.zero
                            codeScannerViewController.infoLabel.text = "Please, scan QR code on the sensor device!"
                            codeScannerViewController.infoLabel.backgroundColor = MODUM_LIGHT_GRAY
                        }
                    })
                }
            }
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sensorConnectViewController = segue.destination as? SensorConnectViewController {
            sensorConnectViewController.sensorMACAddress = sensorMACAddress
            sensorConnectViewController.contractID = contractID
            sensorConnectViewController.isReceivingParcel = isReceivingParcel
        }
    }
    
    // MARK: Helper functions
    
    fileprivate func initialize() {
        /* instatiating video capture */
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
            
            /* initialize frame to highlight QR code */
            scannedCodeFrameView = UIView()
            scannedCodeFrameView?.layer.borderColor = UIColor.green.cgColor
            scannedCodeFrameView?.layer.borderWidth = 2
            view.addSubview(scannedCodeFrameView!)
            view.bringSubview(toFront: scannedCodeFrameView!)
        }
        
        /* UI configuration */
        infoLabel.backgroundColor = MODUM_LIGHT_GRAY
        if isReceivingParcel {
            infoLabel.text = "Please, scan shipment ID on the parcel"
        } else {
            infoLabel.text = "Please, scan shipment ID or QR code on the sensor"
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
