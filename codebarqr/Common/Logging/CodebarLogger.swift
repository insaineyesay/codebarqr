//
//  CodebarLogger.swift
//  codebarqr
//
//  Created by Michael Agee on 8/13/21.
//

import Foundation
import os

class CodebarLogger {
    static let shared = CodebarLogger()
    
    func log(_ message: String, type: OSLogType) {
        print(message)
    }
    
    func logCamera(_ message: StaticString, type: OSLogType, param: CVarArg?) {
        os_log(message, log: Log.camera, type: type)
    }
    
    func logNetworking(_ message: StaticString, type: OSLogType, param: CVarArg?) {
        os_log(message, log: Log.networking, type: type)
    }
    
    func logAds(_ message: StaticString, type: OSLogType, param: CVarArg?) {
        os_log(message, log: Log.networking, type: type)
    }
        
}

// Interface
private let subsystem = "com.ajira.codebarqr"

struct Log {
    public enum LogCategory: String {
        case camera = "camera"
        case networking = "networking"
        case ads = "ads"
    }
    
    static let camera = OSLog(subsystem: subsystem, category: Log.LogCategory.camera.rawValue)
    static let networking = OSLog(subsystem: subsystem, category: Log.LogCategory.networking.rawValue)
    static let ads = OSLog(subsystem: subsystem, category: Log.LogCategory.ads.rawValue)
}
