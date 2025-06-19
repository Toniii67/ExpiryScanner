import SwiftUI
import UIKit

struct NativeAlertController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var showDoneAlert: Bool
    let title: String
    let message: String?
    let viewModel: HomeViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // First Alert (Scan Result)
        if isPresented && !context.coordinator.isAlertPresented {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            // Configure accessibility
            alert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000) // Use raw value for .alert
            alert.view.accessibilityLabel = "\(title). \(message ?? "")"
            alert.view.accessibilityHint = "Ketuk untuk mengulang pengumuman"
            alert.view.isAccessibilityElement = true
            
            // Add tap gesture for re-announcement
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.reAnnounce))
            alert.view.addGestureRecognizer(tapGesture)
            context.coordinator.currentAnnouncement = "\(title). \(message ?? "")"
            
            // Actions
            let scanAgainAction = UIAlertAction(title: "Pindai lagi", style: .default) { _ in
                viewModel.resetDetection()
                isPresented = false
                let dismissalText = "Alert ditutup"
                UIAccessibility.post(notification: .announcement, argument: dismissalText)
                viewModel.speak(text: dismissalText)
                viewModel.playHaptic(type: .pulse)
            }
            scanAgainAction.accessibilityLabel = "Pindai lagi"
            scanAgainAction.accessibilityHint = "Memulai ulang pemindaian"
            alert.addAction(scanAgainAction)
            
            let doneAction = UIAlertAction(title: "Selesai", style: .default) { _ in
                viewModel.markAsDone()
                isPresented = false
            }
            doneAction.accessibilityLabel = "Selesai"
            doneAction.accessibilityHint = "Tandai pemindaian sebagai selesai"
            alert.addAction(doneAction)

            // Present first alert
            context.coordinator.isAlertPresented = true
            DispatchQueue.main.async {
                uiViewController.present(alert, animated: true) {
                    // Announce alert
                    let announcement = "\(title). \(message ?? "")"
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                    viewModel.speak(text: announcement)
                    viewModel.playHaptic(type: .success)
                    UIAccessibility.post(notification: .screenChanged, argument: alert.view)
                }
            }
        }
        // Second Alert (Done Confirmation)
        else if showDoneAlert && !context.coordinator.isDoneAlertPresented {
            let doneAlert = UIAlertController(title: "Pemindaian Selesai", message: "Pemindaian telah ditandai sebagai selesai.", preferredStyle: .alert)
            
            // Configure accessibility
            doneAlert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000) // Fix: Use raw value for .alert
            doneAlert.view.accessibilityLabel = "Pemindaian Selesai. Pemindaian telah ditandai sebagai selesai."
            doneAlert.view.accessibilityHint = "Ketuk untuk mengulang pengumuman"
            doneAlert.view.isAccessibilityElement = true
            
            // Add tap gesture for re-announcement
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.reAnnounce))
            doneAlert.view.addGestureRecognizer(tapGesture)
            context.coordinator.currentAnnouncement = "Pemindaian Selesai. Pemindaian telah ditandai sebagai selesai."
            
            // Action
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                showDoneAlert = false
                let dismissalText = "Alert ditutup"
                UIAccessibility.post(notification: .announcement, argument: dismissalText)
                viewModel.speak(text: dismissalText)
                viewModel.playHaptic(type: .pulse)
            }
            okAction.accessibilityLabel = "OK"
            okAction.accessibilityHint = "Tutup alert dan kembali ke layar utama"
            doneAlert.addAction(okAction)

            // Present second alert
            context.coordinator.isDoneAlertPresented = true
            DispatchQueue.main.async {
                uiViewController.present(doneAlert, animated: true) {
                    // Announce second alert
                    let announcement = "Pemindaian Selesai. Pemindaian telah ditandai sebagai selesai."
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                    viewModel.speak(text: announcement)
                    viewModel.playHaptic(type: .success)
                    UIAccessibility.post(notification: .screenChanged, argument: doneAlert.view)
                }
            }
        }
        // Dismiss alerts
        else if !isPresented && context.coordinator.isAlertPresented {
            uiViewController.dismiss(animated: true) {
                context.coordinator.isAlertPresented = false
            }
        }
        else if !showDoneAlert && context.coordinator.isDoneAlertPresented {
            uiViewController.dismiss(animated: true) {
                context.coordinator.isDoneAlertPresented = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var isAlertPresented = false
        var isDoneAlertPresented = false
        var currentAnnouncement: String?
        
        @objc func reAnnounce() {
            if let announcement = currentAnnouncement {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }
}

