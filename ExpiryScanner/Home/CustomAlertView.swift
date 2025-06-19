//
//  CustomAlertView.swift
//  ExpiryScanner
//
//  Created by Victor Chandra on 19/06/25.
//

import Foundation
import SwiftUI

struct CustomAlertView: View {
    let text: String
    let onDismiss: () -> Void
    @State private var isVisible: Bool = true
    @State private var voiceOverTimer: Timer?
    
    var body: some View {
        if isVisible {
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.7))
                .cornerRadius(10)
                .frame(maxWidth: 280)
                .multilineTextAlignment(.center)
                .accessibilityLabel(NSLocalizedString("Pemindaian Gagal", comment: "Custom alert accessibility label"))
                .accessibilityHint(NSLocalizedString("Peringatan ini akan hilang secara otomatis setelah 10 detik.", comment: "Custom alert accessibility hint"))
                .onAppear {
                    // Auto-dismiss after 10 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if isVisible {
                            onDismiss()
                            isVisible = false
                        }
                    }
                    // VoiceOver looping every 3 seconds
                    if UIAccessibility.isVoiceOverRunning {
                        voiceOverTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                            UIAccessibility.post(notification: .announcement, argument: text)
                        }
                    }
                }
                .onDisappear {
                    voiceOverTimer?.invalidate()
                    voiceOverTimer = nil
                }
        }
    }
}

#Preview {
    CustomAlertView(text: "Sample alert", onDismiss: {})
}
