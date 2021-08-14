//
//  CodebarLogger.swift
//  codebarqr
//
//  Created by Michael Agee on 8/13/21.
//

import Foundation

class CodebarLogger {
    static let shared = CodebarLogger()
    
    // Interface
    func log(_ message: String) {
        if !message.isEmpty {
            print(message)
        } else {
            print("No messages to log")
        }
    }
}
