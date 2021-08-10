//
//  ViewController.swift
//  codebarqr
//
//  Created by Michael Agee on 8/9/21.
//

import AVFoundation
import UIKit

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var sessionService = AVSessionService.shared
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        captureSession = sessionService.captureSession
        let videoInput: AVCaptureDeviceInput
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
                
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
        
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, AVMetadataObject.ObjectType.qr]
        } else {
            failed()
            return
        }
        
        setUpPreviewLayer()
        
    }

    // MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startRunningCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    // MARK: Interface
    func setUpPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        startRunningCaptureSession()
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
//        captureSession = nil
    }
    
    func startRunningCaptureSession() {
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
//        dismiss(animated: true)
    }
    
    func found(code: String) {
        let alert = UIAlertController(title: "ya codes", message: "yeah... your codes is heah: \(code)", preferredStyle: .alert )
        alert.addAction(UIAlertAction(title: "Open in Search..", style: .default, handler: { (action) in
            self.captureSession.stopRunning()
            if let url = URL(string: "https://api.duckduckgo.com/?q=\(code)") {
                UIApplication.shared.open(url)
            }
        }))
        print(code)
        self.present(alert, animated: true)
    }
    
    
}

