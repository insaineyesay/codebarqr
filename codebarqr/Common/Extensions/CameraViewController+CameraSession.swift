////
////  CameraViewController+CameraSession.swift
////  codebarqr
////
////  Created by Michael Agee on 8/17/21.
////
//
//import Foundation
//
//extension ViewController {
//    // MARK: - Camera
//    private func checkPermissions() {
//        // TODO: Checking permissions
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//            case .notDetermined:
//                AVCaptureDevice.requestAccess(for: .video) { [self] granted in
//                    if !granted {
//                        self.showPermissionsAlert()
//                    }
//                }
//            case .denied, .restricted:
//                showPermissionsAlert()
//            default:
//                return
//        }
//    }
//    
//    private func setupCameraLiveView() {
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
//    
//    // MARK: - Vision
//    func processClassification(_ request: VNRequest) {
//        // TODO: Main logic
//        guard let barcodes = request.results else { return }
//        DispatchQueue.main.async { [self] in
//            if captureSession.isRunning {
//                view.layer.sublayers?.removeSubrange(1...)
//                
//                for barcode in barcodes {
//                    guard
//                        // TODO: Check for QR Code symbology and confidence score
//                        let potentialQRCode = barcode as? VNBarcodeObservation,
//                        potentialQRCode.symbology == .QR,
//                        potentialQRCode.confidence > 0.9
//                    else { return }
//                    
//                    observationHandler(payload: potentialQRCode.payloadStringValue)
//                }
//            }
//        }
//    }
//    
//    // MARK: - Handler
//    func observationHandler(payload: String?) {
//        // TODO: Open it in Safari
//        guard
//            let payloadString = payload,
//            let url = URL(string: payloadString),
//            ["http", "https"].contains(url.scheme?.lowercased())
//        else { return }
//        
//        let config = SFSafariViewController.Configuration()
//        config.entersReaderIfAvailable = true
//        
//        let safariVC = SFSafariViewController(url: url, configuration: config)
//        safariVC.delegate = self
//        present(safariVC, animated: true)
//    }
//}
//
//extension ViewController {
//    private func configurePreviewLayer() {
//        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        cameraPreviewLayer.videoGravity = .resizeAspectFill
//        cameraPreviewLayer.connection?.videoOrientation = .portrait
//        cameraPreviewLayer.frame = view.frame
//        view.layer.insertSublayer(cameraPreviewLayer, at: 0)
//    }
//    
//    private func showAlert(withTitle title: String, message: String) {
//        DispatchQueue.main.async {
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: "OK", style: .default))
//            self.present(alertController, animated: true)
//        }
//    }
//    
//    private func showPermissionsAlert() {
//        showAlert(
//            withTitle: "Camera Permissions",
//            message: "Please open Settings and grant permission for this app to use your camera.")
//    }
//}
