//
//  AVSessionService.swift
//  codebarqr
//
//  Created by Michael Agee on 8/10/21.
//

import Foundation
import AVFoundation
import UIKit

public struct AVSessionService {
    static let shared = AVSessionService()
    let captureSession = AVCaptureSession()
    let videoCaptureDevice: AVCaptureDevice!
    
    public init() {
        videoCaptureDevice = AVCaptureDevice.default(for: .video)
    }
        
 
    func startRunningCaptureSession() {
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
}
    
