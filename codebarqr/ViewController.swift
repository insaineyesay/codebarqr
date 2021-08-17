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
import Vision

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, SFSafariViewControllerDelegate, GADFullScreenContentDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    // reference for the google ad interstitial
    private var interstitial: GADInterstitialAd?
    let logger = CodebarLogger.shared
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
    lazy var detectBarcodeRequest = VNDetectBarcodesRequest {
        request, error in
        guard error == nil else {
            self.showAlert(withTitle: "Barcode Error", message: error?.localizedDescription ?? "error", actionButtonText: "OK")
            return
        }
        
        self.processClassification(request)
    }
    
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
        
        checkPermissions()
        // TODO: Need to move all Google Ad functionalities to a service
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnitID,
                               request: request,
                               completionHandler: {[self] ad, error in
                                if let error = error {
                                    logger.logAds("Failed to load interstitial ad with error: %d", type: .error, param: nil)
                                    logger.log("interstital ad error: \(error)", type: .error)
                                    return
                                }
                                interstitial = ad
                                interstitial?.fullScreenContentDelegate = self
                               })
        
        view.backgroundColor = UIColor.black
        // set the global capture session
        captureSession = sessionService.captureSession
        // set the video capture preset resolution
        captureSession.sessionPreset = .hd4K3840x2160
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
        logger.log("Ad did fail to present full screen content.", type: .info)
        if let barcode = barcode {
            openWebSearch(barcode)
            clearBarcode()
        }
    }
    
    /// Tells the delegate that the ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        logger.log("Ad did present full screen content.", type: .info)
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        logger.log("Ad did dismiss full screen content.", type: .info)
        if let barcode = barcode {
            openWebSearch(barcode)
        }
    }
    
    // MARK: Lifecycle Overrides
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
        } else {
            logger.log("couldn't open web search for barcode.", type: .error)
        }
    }
    
    func clearBarcode() {
        barcode = ""
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
        
        //        let captureOutput = AVCaptureVideoDataOutput()
        //        // TODO: Set video sample rate
        //        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        //        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        //        captureSession.addOutput(captureOutput)
        
        startRunningCaptureSession()
    }
    
    private func showAlert(withTitle title: String, message: String, actionButtonText: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alertController, animated: true)
        }
    }
    
    func failed() {
        showAlert(withTitle: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", actionButtonText: "OK")
    }
    
    func startRunningCaptureSession() {
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // TODO: Live Vision
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right)
        
        do {
            try imageRequestHandler.perform([detectBarcodeRequest])
        } catch {
            print(error)
        }
    }
    
    
    func found(code: String) {
        if code.contains("http") {
            // TODO: Open it in Safari if has a URL associated, otherwise do a duck duck go api request
//            let payloadString = code
//            guard
//                let url = URL(string: payloadString),
//                ["http", "https"].contains(url.scheme?.lowercased())
//            else { return }
//
//            let config = SFSafariViewController.Configuration()
//            config.entersReaderIfAvailable = true
//
//            let safariVC = SFSafariViewController(url: url, configuration: config)
//            safariVC.delegate = self
//
//            showGoogleAds()
//
//            present(safariVC, animated: true)
            observationHandler(payload: code)
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
            interstitial?.present(fromRootViewController: self)
        } else {
            logger.log("Ad wasn't ready", type: .info)
//            if let barcode = barcode {
//                if barcode.contains("http") {
//                    observationHandler(payload: barcode)
//                }
//                openWebSearch(barcode)
//            }
        }
    }
}

extension ViewController {
    // MARK: - Camera
    private func checkPermissions() {
        // TODO: Checking permissions
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [self] granted in
                    if !granted {
                        self.showPermissionsAlert()
                    }
                }
            case .denied, .restricted:
                showPermissionsAlert()
            default:
                return
        }
    }
    
    //     private func setupCameraLiveView() {
    //        // TODO: Setup captureSession
    //        captureSession.sessionPreset = .hd1280x720
    //
    //        // TODO: Add input
    //        let videoDevice = AVCaptureDevice
    //            .default(.builtInWideAngleCamera, for: .video, position: .back)
    //
    //        guard
    //            let device = videoDevice,
    //            let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
    //            captureSession.canAddInput(videoDeviceInput) else {
    //            showAlert(
    //                withTitle: "Cannot Find Camera",
    //                message: "There seems to be a problem with the camera on your device.")
    //            return
    //        }
    //
    //        captureSession.addInput(videoDeviceInput)
    //
    //        // TODO: Add output
    //        let captureOutput = AVCaptureVideoDataOutput()
    //        // TODO: Set video sample rate
    //        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
    //        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
    //        captureSession.addOutput(captureOutput)
    //
    //        configurePreviewLayer()
    //
    //        // TODO: Run session
    //        captureSession.startRunning()
    //    }
    
    // MARK: - Vision
    func processClassification(_ request: VNRequest) {
        // 1
        guard let barcodes = request.results else { return }
        DispatchQueue.main.async { [self] in
            if captureSession.isRunning {
                view.layer.sublayers?.removeSubrange(1...)
                
                // 2
                for barcode in barcodes {
                    guard
                        // TODO: Check for QR Code symbology and confidence score
                        let potentialQRCode = barcode as? VNBarcodeObservation,
                        potentialQRCode.confidence > 0.9
                    else { return }
                    
                    // 3
                    //                    showAlert(
                    //                        withTitle: potentialQRCode.symbology.rawValue,
                    //                        // TODO: Check the confidence score
                    //                        message: String(potentialQRCode.confidence), actionButtonText: "OK")
                    
//                    if potentialQRCode.symbology == .QR {
//                        print("wtf man")
//                        observationHandler(payload: potentialQRCode.payloadStringValue)
//                    } else {
//                        print("is this thing on")
//                        if let barcode = potentialQRCode.payloadStringValue {
//                            found(code: barcode)
//                        }
//                    }
                }
            }
            
        }
    }
    
    // MARK: - Handler
    func observationHandler(payload: String?) {
        // TODO: Open it in Safari
        guard
            let payloadString = payload,
            let url = URL(string: payloadString),
            ["http", "https"].contains(url.scheme?.lowercased())
        else { return }
        
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        //        dismiss(animated: true)
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.delegate = self
        present(safariVC, animated: true)
    }
}

extension ViewController {
    private func configurePreviewLayer() {
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewLayer.frame = view.frame
        view.layer.insertSublayer(cameraPreviewLayer, at: 0)
    }
    
    private func showAlert(withTitle title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alertController, animated: true)
        }
    }
    
    private func showPermissionsAlert() {
        showAlert(
            withTitle: "Camera Permissions",
            message: "Please open Settings and grant permission for this app to use your camera.")
    }
}
