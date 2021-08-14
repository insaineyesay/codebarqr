//
//  ViewController.swift
//  codebarqr
//
//  Created by Michael Agee on 8/9/21.
//

import AVFoundation
import UIKit
import SwiftUI
import SafariServices
import GoogleMobileAds

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, SFSafariViewControllerDelegate, GADFullScreenContentDelegate {
    // reference for the google ad interstitial
    private var interstitial: GADInterstitialAd?
    // create an instance of the AV Session service
    var sessionService = AVSessionService.shared
    // Create a capture session to connect inputs and outputs to
    var captureSession = AVCaptureSession()
    // Add a preview layer so that the camear input can be viewed
    var previewLayer: AVCaptureVideoPreviewLayer!
    // Create a UIView to act as a transparent layer over the camera view
    let backgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return v
    }()
    
    var barcode: String?
    
    #if DEBUG
    var adUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    var adUnitID = "ca-app-pub-7134449571312427/9058003570"
    #endif
    
    // Reference to storyboard UIView
    @IBOutlet weak var camOverlayImageView: UIImageView!
    // Hide the status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    // Only support portrait mode. This could also be done in the info.plist settings
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Need to move all Google Ad functionalities to a service
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: "ca-app-pub-3940256099942544/4411468910",
                               request: request,
                               completionHandler: {[self] ad, error in
                                if let error = error {
                                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                    return
                                }
                                interstitial = ad
                                interstitial?.fullScreenContentDelegate = self
                               })
        
        view.backgroundColor = UIColor.black
        // set the global capture session
        captureSession = sessionService.captureSession
        // set up an input
        let videoInput: AVCaptureDeviceInput
        // set up an output
        let metadataOutput = AVCaptureMetadataOutput()
        // find a capture device for video (which is also used for images)
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        // if we can't assign the capture device as an input, fail
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
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, AVMetadataObject.ObjectType.qr, .code39, .code128, .dataMatrix, .upce]
        } else {
            failed()
            return
        }
        
        setUpPreviewLayer()
        
    }
    
    // MARK: Goole Add stuff
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        if let barcode = barcode {
            openWebSearch(barcode)
        }
    }
    
    /// Tells the delegate that the ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        if let barcode = barcode {
            openWebSearch(barcode)
        }
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Create the initial layer from the view bounds.
        let maskLayer = CAShapeLayer()
        maskLayer.frame = backgroundView.bounds
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.lineDashPattern = [50, 275, 50, 0, 50, 155, 50, 0, 50, 275, 50, 0, 50, 157, 50]
        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.lineWidth = 5
        
        // Create the path.
        let path = UIBezierPath(rect: backgroundView.bounds)
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        // Append the overlay image to the path so that it is subtracted.
        path.append(UIBezierPath(rect: camOverlayImageView.frame))
        maskLayer.path = path.cgPath
        
        // Set the mask of the view.
        backgroundView.layer.mask = maskLayer
    }
    
    // MARK: Interface
    
    func openWebSearch(_ code: String) {
        if let url = URL(string: "https://google.com/search?q=\(code)&tbm=shop") {
            UIApplication.shared.open(url)
        }
    }
    func setUpPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
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
        if code.contains("http") {
            // TODO: Open it in Safari if has a URL associated, otherwise do a duck duck go api request
            let payloadString = code
            guard
                let url = URL(string: payloadString),
                ["http", "https"].contains(url.scheme?.lowercased())
            else { return }
            
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            
            let safariVC = SFSafariViewController(url: url, configuration: config)
            safariVC.delegate = self
            
            showGoogleAds()
            
            present(safariVC, animated: true)
        } else {
            showGoogleAds()
            barcode = code
            //            if !code.isEmpty {
            //                let group = DispatchGroup()
            //
            //                let urls = [
            //                    URL(string: "https://www.target.com/s?searchTerm=\(code)"),
            //                    URL(string: "https://google.com/search?q=\(code)"),
            //                    URL(string: "https://amazon.com/s?k=\(code)")
            //                ]
            //                UIApplication.shared.open(url)
            //                for url in urls {
            //                    group.enter()
            //                    if let url = url { performRequest(urlString: url) }
            //                }
            //            }
        }
    }
    
    func showGoogleAds() {
        // show google interstitial ad
        if interstitial != nil {
            print("google ads!")
            interstitial?.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
    }
    
    func performRequest(urlString: URL) {
        // 1. Create a URL
        let url = urlString
        print("url = \(url)")
        // 2. Create a URL Session
        let session = URLSession(configuration: .default)
        // 3. Create a session task
        let task = session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            if let safeData = data {
                print("data returned!")
            }
        }
        // 4. Start the task
        task.resume()
    }
}
