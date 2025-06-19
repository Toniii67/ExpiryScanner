//import SwiftUI
//import UIKit
//
//struct NativeAlertController: UIViewControllerRepresentable {
//    @Binding var isPresented: Bool
//    @Binding var showDoneAlert: Bool
//    let title: String
//    let message: String?
//    let viewModel: CameraViewModel
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        let controller = UIViewController()
//        controller.view.backgroundColor = .clear
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        // First Alert (Scan Result)
//        if isPresented && !context.coordinator.isAlertPresented {
//            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//            // Configure accessibility
//            alert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000) // Use raw value for .alert
//            alert.view.accessibilityLabel = "\(title). \(message ?? "")"
//            alert.view.accessibilityHint = "Ketuk untuk mengulang pengumuman"
//            alert.view.isAccessibilityElement = true
//
//            // Add tap gesture for re-announcement
//            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.reAnnounce))
//            alert.view.addGestureRecognizer(tapGesture)
//            context.coordinator.currentAnnouncement = "\(title). \(message ?? "")"
//
//            // Actions
//            let scanAgainAction = UIAlertAction(title: "Pindai lagi", style: .default) { _ in
//                viewModel.resetDetection()
//                isPresented = false
//                let dismissalText = "Alert ditutup"
//                UIAccessibility.post(notification: .announcement, argument: dismissalText)
//                viewModel.speak(text: dismissalText)
//                viewModel.playHaptic(type: .pulse)
//            }
//            scanAgainAction.accessibilityLabel = "Pindai lagi"
//            scanAgainAction.accessibilityHint = "Memulai ulang pemindaian"
//            alert.addAction(scanAgainAction)
//
//            let doneAction = UIAlertAction(title: "Selesai", style: .default) { _ in
//                viewModel.markAsDone()
//                isPresented = false
//            }
//            doneAction.accessibilityLabel = "Selesai"
//            doneAction.accessibilityHint = "Tandai pemindaian sebagai selesai"
//            alert.addAction(doneAction)
//
//            // Present first alert
//            context.coordinator.isAlertPresented = true
//            DispatchQueue.main.async {
//                uiViewController.present(alert, animated: true) {
//                    // Announce alert
//                    let announcement = "\(title). \(message ?? "")"
//                    UIAccessibility.post(notification: .announcement, argument: announcement)
//                    viewModel.speak(text: announcement)
//                    viewModel.playHaptic(type: .success)
//                    UIAccessibility.post(notification: .screenChanged, argument: alert.view)
//                }
//            }
//        }
//        // Second Alert (Done Confirmation)
//        else if showDoneAlert && !context.coordinator.isDoneAlertPresented {
//            let doneAlert = UIAlertController(title: "Pemindaian Selesai", message: "Pemindaian telah ditandai sebagai selesai.", preferredStyle: .alert)
//
//            // Configure accessibility
//            doneAlert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000) // Fix: Use raw value for .alert
//            doneAlert.view.accessibilityLabel = "Pemindaian Selesai. Pemindaian telah ditandai sebagai selesai."
//            doneAlert.view.accessibilityHint = "Ketuk untuk mengulang pengumuman"
//            doneAlert.view.isAccessibilityElement = true
//
//            // Add tap gesture for re-announcement
//            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.reAnnounce))
//            doneAlert.view.addGestureRecognizer(tapGesture)
//            context.coordinator.currentAnnouncement = "Pemindaian Selesai. Pemindaian telah ditandai sebagai selesai."
//
//            // Action
//            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
//                showDoneAlert = false
//                let dismissalText = "Alert ditutup"
//                UIAccessibility.post(notification: .announcement, argument: dismissalText)
//                viewModel.speak(text: dismissalText)
//                viewModel.playHaptic(type: .pulse)
//            }
//            okAction.accessibilityLabel = "OK"
//            okAction.accessibilityHint = "Tutup alert dan kembali ke layar utama"
//            doneAlert.addAction(okAction)
//
//            // Present second alert
//            context.coordinator.isDoneAlertPresented = true
//            DispatchQueue.main.async {
//                uiViewController.present(doneAlert, animated: true) {
//                    // Announce second alert
//                    let announcement = "Pemindaian Selesai. Pemindaian telah ditandai sebagai selesai."
//                    UIAccessibility.post(notification: .announcement, argument: announcement)
//                    viewModel.speak(text: announcement)
//                    viewModel.playHaptic(type: .success)
//                    UIAccessibility.post(notification: .screenChanged, argument: doneAlert.view)
//                }
//            }
//        }
//        // Dismiss alerts
//        else if !isPresented && context.coordinator.isAlertPresented {
//            uiViewController.dismiss(animated: true) {
//                context.coordinator.isAlertPresented = false
//            }
//        }
//        else if !showDoneAlert && context.coordinator.isDoneAlertPresented {
//            uiViewController.dismiss(animated: true) {
//                context.coordinator.isDoneAlertPresented = false
//            }
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator {
//        var isAlertPresented = false
//        var isDoneAlertPresented = false
//        var currentAnnouncement: String?
//
//        @objc func reAnnounce() {
//            if let announcement = currentAnnouncement {
//                UIAccessibility.post(notification: .announcement, argument: announcement)
//            }
//        }
//    }
//}
//import SwiftUI
//import UIKit
//
//struct NativeAlertController: UIViewControllerRepresentable {
//    @Binding var finalAlertType: CameraView.FinalAlertType?
//    let viewModel: CameraViewModel
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        let controller = UIViewController()
//        controller.view.backgroundColor = .clear
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//            return // Skip alert presentation in preview
//        }
//
//        guard let alertType = finalAlertType, !context.coordinator.isAlertPresented else {
//            if finalAlertType == nil && context.coordinator.isAlertPresented {
//                uiViewController.dismiss(animated: true) {
//                    context.coordinator.isAlertPresented = false
//                    context.coordinator.currentAnnouncement = nil
//                }
//            }
//            return
//        }
//
//        let title = NSLocalizedString("Hasil Pemindaian", comment: "Scan result title")
//        var message: String
//        switch alertType {
//        case .noneDetected:
//            message = NSLocalizedString("Produk tidak ditemukan", comment: "None detected text")
//        case .partialDetected(let name, let date):
//            message = NSLocalizedString("Hasil deteksi objek: \(name ?? "data tidak ditemukan"), \(date?.formatted(date: .long, time: .omitted) ?? "data tidak ditemukan")", comment: "Partial detected text")
//        case .bothDetected(let name, let date):
//            message = NSLocalizedString("Hasil deteksi objek: \(name), \(date.formatted(date: .long, time: .omitted))", comment: "Both detected text")
//        }
//
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//        // Configure accessibility
//        alert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000) // Alert trait
//        alert.view.accessibilityLabel = "\(title). \(message)"
//        alert.view.accessibilityHint = NSLocalizedString("Ketuk untuk mengulang pengumuman", comment: "Accessibility hint")
//        alert.view.isAccessibilityElement = true
//
//        // Add tap gesture for re-announcement
//        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.reAnnounce))
//        alert.view.addGestureRecognizer(tapGesture)
//        context.coordinator.currentAnnouncement = "\(title). \(message)"
//
//        // Actions
//        let redoAction = UIAlertAction(title: NSLocalizedString("Ulangi", comment: "Redo button"), style: .default) { _ in
//            viewModel.resetDetection()
//            finalAlertType = nil
//            let dismissalText = NSLocalizedString("Alert ditutup", comment: "Dismissal text")
//            UIAccessibility.post(notification: .announcement, argument: dismissalText)
//            viewModel.speak(text: dismissalText)
//            viewModel.playHaptic(type: .pulse)
//        }
//        redoAction.accessibilityLabel = NSLocalizedString("Ulangi", comment: "Redo button")
//        redoAction.accessibilityHint = NSLocalizedString("Memulai ulang pemindaian", comment: "Redo accessibility hint")
//        alert.addAction(redoAction)
//
//        if case .bothDetected = alertType {
//            let doneAction = UIAlertAction(title: NSLocalizedString("Selesai", comment: "Done button"), style: .default) { _ in
//                viewModel.markAsDone()
//                finalAlertType = nil
//                let dismissalText = NSLocalizedString("Pemindaian selesai", comment: "Done dismissal text")
//                UIAccessibility.post(notification: .announcement, argument: dismissalText)
//                viewModel.speak(text: dismissalText)
//                viewModel.playHaptic(type: .success)
//            }
//            doneAction.accessibilityLabel = NSLocalizedString("Selesai", comment: "Done button")
//            doneAction.accessibilityHint = NSLocalizedString("Tandai pemindaian sebagai selesai", comment: "Done accessibility hint")
//            alert.addAction(doneAction)
//        }
//
//        // Present alert
//        context.coordinator.isAlertPresented = true
//        DispatchQueue.main.async {
//            uiViewController.present(alert, animated: true) {
//                // Announce alert
//                let announcement = "\(title). \(message)"
//                UIAccessibility.post(notification: .announcement, argument: announcement)
//                viewModel.speak(text: announcement)
//                viewModel.playHaptic(type: .success)
//                UIAccessibility.post(notification: .screenChanged, argument: alert.view)
//            }
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator {
//        var isAlertPresented = false
//        var currentAnnouncement: String?
//
//        @objc func reAnnounce() {
//            if let announcement = currentAnnouncement {
//                UIAccessibility.post(notification: .announcement, argument: announcement)
//            }
//        }
//    }
//}
import SwiftUI
import UIKit

struct NativeAlertController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var showDoneAlert: Bool
    let title: String
    let message: String?
    let viewModel: CameraViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Dismiss alert if needed
        if !isPresented && context.coordinator.isAlertPresented {
            uiViewController.dismiss(animated: true) {
                context.coordinator.isAlertPresented = false
                context.coordinator.currentAnnouncement = nil
            }
        } else if !showDoneAlert && context.coordinator.isDoneAlertPresented {
            uiViewController.dismiss(animated: true) {
                context.coordinator.isDoneAlertPresented = false
                context.coordinator.currentAnnouncement = nil
            }
        }

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }

        // First Alert (Scan Result)
        if isPresented && !context.coordinator.isAlertPresented {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            // Configure accessibility
            alert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000) // Alert trait
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
            doneAlert.view.accessibilityTraits = UIAccessibilityTraits(rawValue: 0x1000000000000)
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
