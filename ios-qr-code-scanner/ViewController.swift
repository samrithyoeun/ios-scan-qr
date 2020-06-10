//
//  ViewController.swift
//  ios-qr-code-scanner
//
//  Created by Yoeun Samrith on 6/9/20.
//  Copyright © 2020 Yoeun Samrith. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var centerView: UIView!
    
    private var cornerRadius: CGFloat = 25.0
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var maskView: UIView!
    private var metadataOutput: AVCaptureMetadataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareForScanning()
        setupCenterView()
        
    }
    
    func setupCenterView() {
        let backgroundView = UIView()
        backgroundView.frame = view.bounds
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0.5
        self.view.addSubview(backgroundView)
        
        maskView = UIView()
        maskView.frame = centerView.bounds
        maskView.backgroundColor = .black
        
        maskView.layer.cornerRadius = cornerRadius
        centerView.layer.cornerRadius = cornerRadius
        maskView.alpha = 0.4
        
        centerView.backgroundColor = .lightGray
        centerView.alpha = 0.4
        centerView.mask = maskView
        
        
        centerView.transform = CGAffineTransform.identity.scaledBy(x: 1.02, y: 1.02)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.centerView.transform = CGAffineTransform.identity
            self.centerView.alpha = 0.2
            
        })
        
        self.view.bringSubviewToFront(backgroundView)
        self.view.bringSubviewToFront(centerView)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func prepareForScanning() {
        setupCenterView()
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        metadataOutput = AVCaptureMetadataOutput()
        
        
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        print("maskViewbound --- \(centerView.frame)")
        metadataOutput.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: centerView.frame)
        
        
    }
    
    func startScanning() {
        captureSession.startRunning()
        metadataOutput.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: centerView.frame)
    }
    
    func found(content: String) {
        
        UIAlertController.show(content, in: self, action: {
            self.startScanning()
        })
        
    }

  
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(content: stringValue)
        }
    }
}


extension UIAlertController {
    static func show(_ message: String, in viewController: UIViewController, action: (()->())? =  nil) {
        let alert = UIAlertController()
        alert.message = message
        let okayAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            action?()
        })
        alert.addAction(okayAction)
        viewController.present(alert, animated: true, completion: nil)
        
    }
}
