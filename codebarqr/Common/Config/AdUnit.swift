//
//  AdUnit.swift
//  codebarqr
//
//  Created by Michael Agee on 8/17/21.
//

import Foundation

class AdUnitConfig {
    static let shared = AdUnitConfig()
    let adUnitID: String?
    
    init () {
        #if DEBUG
        adUnitID = "ca-app-pub-3940256099942544/4411468910"
        #else
        adUnitID = "ca-app-pub-7134449571312427/9058003570"
        #endif
    }
}
