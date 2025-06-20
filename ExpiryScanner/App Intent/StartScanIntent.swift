//
//  StartScanIntent.swift
//  ExpiryScanner
//
//  Created by Victor Chandra on 19/06/25.
//

import Foundation
import AppIntents
import SwiftUI

struct StartScanIntent: AppIntent {
    // Title that appears in the Shortcuts app
    static var title: LocalizedStringResource = "Start a New Scan"
    
    // How the intent is described in the Shortcuts app
    static var description = IntentDescription("Opens ExpiryScanner to start scanning a product.")
    
    // FIX: This is a static property that configures the intent's behavior.
    // It should not have the @Parameter property wrapper.
    static var openAppWhenRun: Bool = true
    
    // The perform function is simple because the system handles opening the app.
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
