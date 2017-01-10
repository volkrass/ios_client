//
//  QRScanner.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 27.11.16.
//  Copyright © 2016 Modum. All rights reserved.
//

import AVFoundation
import UIKit

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: Properties
    
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var qrCodeFrameView: UIView?
    
    fileprivate var isSensorMACDiscovered: Bool = false
    
    // MARK: Outlets
    
    @IBOutlet weak fileprivate var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            /* initialize video preview layer */
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            view.bringSubview(toFront: infoLabel)
            
            /* initialize frame to highlight QR code */
            qrCodeFrameView = UIView()
            qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView?.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView!)
            view.bringSubview(toFront: qrCodeFrameView!)
        }
        
        /* UI configuration */
        infoLabel.backgroundColor = MODUM_LIGHT_GRAY
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if metadataObjects == nil || metadataObjects.isEmpty {
            qrCodeFrameView?.frame = CGRect.zero
            infoLabel.text = "No QR code is detected"
            infoLabel.backgroundColor = MODUM_LIGHT_GRAY
            return
        }
        
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObject.type == AVMetadataObjectTypeQRCode, let videoPreviewLayer = videoPreviewLayer {
            let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObject as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds;
            
            if metadataObject.stringValue != nil && !isSensorMACDiscovered {
                infoLabel.text = metadataObject.stringValue
//                if isValidMacAddress(metadataObject.stringValue) {
//                    isSensorMACDiscovered = true
//                    infoLabel.backgroundColor = UIColor.green
//                    let sensorConnectController = SensorConnectViewController(nibName: nil, bundle: nil)
//                    present(sensorConnectController, animated: false, completion: nil)
//                } else {
//                    infoLabel.backgroundColor = UIColor.red
//                }
                isSensorMACDiscovered = true
                infoLabel.backgroundColor = UIColor.green
                let sensorConnectController = SensorConnectViewController(nibName: nil, bundle: nil)
                present(sensorConnectController, animated: false, completion: nil)
            }
        }
    }
    
}
