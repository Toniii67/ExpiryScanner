//
//  AppShortcutsProvider.swift
//  ExpiryScanner
//
//  Created by Victor Chandra on 19/06/25.
//

import Foundation
import AppIntents

struct ExpiryScannerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartScanIntent(),
            phrases: [
                "Scan an expiry date with \(.applicationName)",
                "Start scanning with \(.applicationName)",
                "Pindai kadaluwarsa dengan \(.applicationName)",
                "Mulai memindai dengan \(.applicationName)"
            ],
            shortTitle: "Start Scan",
            systemImageName: "barcode.viewfinder"
        )
    }
}
