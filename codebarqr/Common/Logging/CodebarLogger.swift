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
    
    func log(_ message: StaticString) {
        os_log(message, log: Log.camera)
    }
        
}

// Interface
private let subsystem = "com.ajira.codebarqr"

struct Log {
    static let camera = OSLog(subsystem: subsystem, category: "camera")
}
