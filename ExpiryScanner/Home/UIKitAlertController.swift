//
//  UIKitAlertController.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 20/06/25.
//

import SwiftUI
import UIKit

struct UIKitAlertController: UIViewControllerRepresentable {
    let title: String
    let message: String
    let actions: [UIAlertAction]

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard uiViewController.presentedViewController == nil else { return }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alertController.addAction($0) }

        DispatchQueue.main.async {
            uiViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
