//import SwiftUI
//import UIKit
//import AVFoundation
//
//struct CameraView: View {
//    @StateObject private var viewModel = CameraViewModel()
//    @State private var currentAlert: AlertType? = nil
//    @State private var currentGuidanceText = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuikan jarak hp dan barang yang ingin di scan", comment: "Initial guidance text")
//    @State private var showCustomAlert: Bool = false
//    
//    enum AlertType: Identifiable {
//        case guidance
//        
//        var id: String {
//            "guidance"
//        }
//    }
//    
//    // Function to trigger success haptic feedback
//    private func triggerSuccessHaptic() {
//        let generator = UINotificationFeedbackGenerator()
//        generator.prepare()
//        generator.notificationOccurred(.success)
//    }
//    
//    // Function to speak text in Indonesian as fallback
//    private func speakInIndonesian(_ text: String) {
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
//        utterance.rate = 0.5
//        let synthesizer = AVSpeechSynthesizer()
//        synthesizer.stopSpeaking(at: .immediate)
//        synthesizer.speak(utterance)
//    }
//    
//    var body: some View {
//        ZStack {
//            CameraViewControllerRepresentable(viewModel: viewModel)
//                .ignoresSafeArea()
//            
//            VStack {
//                // Custom Alert
//                if showCustomAlert {
//                    CustomAlertView(
//                        text: NSLocalizedString("Silakan tahan posisi Anda dan putar item secara perlahan ke segala arah selama 10 detik saat proses pemindaian berlangsung", comment: "Custom alert text"),
//                        onDismiss: {
//                            triggerSuccessHaptic()
//                            showCustomAlert = false
//                        }
//                    )
//                    .padding(.top, 20)
//                }
//                
//                // Scanner Frame
//                scannerFrameView
//                    .frame(width: 280, height: 500)
//                
//                Spacer()
//            }
//            .padding()
//            .background(
//                NativeAlertController(
//                    isPresented: $viewModel.showAlert,
//                    showDoneAlert: $viewModel.showDoneAlert,
//                    title: NSLocalizedString("Hasil Pemindaian", comment: "Scan result title"),
//                    message: {
//                        if let date = viewModel.detectedExpiryDate, let name = viewModel.detectedProductName {
//                            return "\(name) Kadaluwarsa pada \(date.formatted(date: .long, time: .omitted))"
//                        }
//                        return nil
//                    }(),
//                    viewModel: viewModel
//                )
//            )
//        }
//        .alert(item: $currentAlert) { _ in
//            Alert(
//                title: Text(NSLocalizedString("Petunjuk Pemindaian", comment: "Guidance alert title")),
//                message: Text(currentGuidanceText),
//                dismissButton: .default(Text(NSLocalizedString("OK", comment: "Dismiss button"))) {
//                    print("Guidance alert dismissed")
//                    triggerSuccessHaptic()
//                    currentAlert = nil
//                    // Check if scan failed
//                    if viewModel.detectedProductName == nil && viewModel.detectedExpiryDate == nil {
//                        showCustomAlert = true
//                        let customText = NSLocalizedString("Silakan tahan posisi Anda dan putar item secara perlahan ke segala arah selama 10 detik saat proses pemindaian berlangsung", comment: "Custom alert text")
//                        UIAccessibility.post(notification: .announcement, argument: customText)
//                        speakInIndonesian(customText)
//                    }
//                }
//            )
//        }
//        .onAppear {
//            let text = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuikan jarak hp dan barang yang ingin di scan", comment: "Initial guidance text")
//            currentGuidanceText = text
//            print("Setting initial guidance: \(text)")
//            // Delay to ensure view initialization
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                currentAlert = .guidance
//                UIAccessibility.post(notification: .screenChanged, argument: text)
//                speakInIndonesian(text)
//            }
//            viewModel.startSession()
//        }
//    }
//    
//    // Custom Alert View
//    struct CustomAlertView: View {
//        let text: String
//        let onDismiss: () -> Void
//        @State private var isVisible: Bool = true
//        @State private var voiceOverTimer: Timer?
//        
//        var body: some View {
//            if isVisible {
//                Text(text)
//                    .font(.body)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.gray.opacity(0.7))
//                    .cornerRadius(10)
//                    .frame(maxWidth: 280)
//                    .multilineTextAlignment(.center)
//                    .accessibilityLabel(NSLocalizedString("Pemindaian Gagal", comment: "Custom alert accessibility label"))
//                    .accessibilityHint(NSLocalizedString("Peringatan ini akan hilang secara otomatis setelah 10 detik.", comment: "Custom alert accessibility hint"))
//                    .onAppear {
//                        // Auto-dismiss after 10 seconds
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//                            if isVisible {
//                                onDismiss()
//                                isVisible = false
//                            }
//                        }
//                        // VoiceOver looping every 3 seconds
//                        if UIAccessibility.isVoiceOverRunning {
//                            voiceOverTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
//                                UIAccessibility.post(notification: .announcement, argument: text)
//                            }
//                        }
//                    }
//                    .onDisappear {
//                        voiceOverTimer?.invalidate()
//                        voiceOverTimer = nil
//                    }
//            }
//        }
//    }
//    
//    // Scanner Frame
//    private var scannerFrameView: some View {
//        GeometryReader { geometry in
//            let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round)
//            let dashedStrokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, dash: [1, 2])
//            let color = Color.white
//
//            ZStack {
//                // Corner Brackets
//                CornerBracket(corner: .topLeft, lineLength: 50).stroke(style: strokeStyle)
//                CornerBracket(corner: .topRight, lineLength: 50).stroke(style: strokeStyle)
//                CornerBracket(corner: .bottomLeft, lineLength: 50).stroke(style: strokeStyle)
//                CornerBracket(corner: .bottomRight, lineLength: 50).stroke(style: strokeStyle)
//
//                // Dashed Lines
//                Path { path in
//                    path.move(to: CGPoint(x: geometry.size.width * 0.3, y: 0))
//                    path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: 0))
//                }.stroke(style: dashedStrokeStyle)
//                
//                Path { path in
//                    path.move(to: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height))
//                    path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height))
//                }.stroke(style: dashedStrokeStyle)
//                
//                Path { path in
//                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
//                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.7))
//                }.stroke(style: dashedStrokeStyle)
//                
//                Path { path in
//                    path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.3))
//                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.7))
//                }.stroke(style: dashedStrokeStyle)
//            }
//            .foregroundColor(color)
//        }
//        .accessibilityElement(children: .combine)
//        .accessibilityLabel(NSLocalizedString("Object detection frame", comment: "Scanner frame accessibility label"))
//        .accessibilityHint(NSLocalizedString("Position the item you want to scan inside this frame.", comment: "Scanner frame accessibility hint"))
//    }
//}
//
//private struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
//    var viewModel: CameraViewModel
//    
//    func makeUIViewController(context: Context) -> CameraViewController {
//        CameraViewController(viewModel: viewModel)
//    }
//    
//    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
//}
//
//#Preview {
//    CameraView()
//}

import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @State private var showGuidanceAlert: Bool = false
    @State private var currentGuidanceText = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuikan jarak hp dan barang yang ingin di scan", comment: "Initial guidance text")
    @State private var showCustomAlert: Bool = false
    @State private var finalAlertType: FinalAlertType? = nil
    @State private var refreshID = UUID() // Hack to force preview refresh
    
    init(viewModel: CameraViewModel = CameraViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    enum FinalAlertType: Identifiable {
        case noneDetected
        case partialDetected(name: String?, date: Date?)
        case bothDetected(name: String, date: Date)
        
        var id: String {
            switch self {
            case .noneDetected: return "noneDetected"
            case .partialDetected: return "partialDetected"
            case .bothDetected: return "bothDetected"
            }
        }
    }
    
    // Function to trigger success haptic feedback
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    // Function to speak text in Indonesian as fallback
    private func speakInIndonesian(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
        utterance.rate = 0.5
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
    
    var body: some View {
        ZStack {
            // Conditional camera view for preview
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                Color.gray // Placeholder for preview
                    .ignoresSafeArea()
            } else {
                CameraViewControllerRepresentable(viewModel: viewModel)
                    .ignoresSafeArea()
            }
            
            VStack {
                // Custom Alert
                if showCustomAlert {
                    CustomAlertView(
                        text: NSLocalizedString("Silakan tahan posisi Anda dan putar item secara perlahan ke segala arah selama 10 detik saat proses pemindaian berlangsung", comment: "Custom alert text"),
                        onDismiss: {
                            triggerSuccessHaptic()
                            showCustomAlert = false
                            // Trigger final alert based on detection results
                            if viewModel.detectedProductName == nil && viewModel.detectedExpiryDate == nil {
                                finalAlertType = .noneDetected
                                let text = NSLocalizedString("Produk tidak ditemukan", comment: "None detected text")
                                UIAccessibility.post(notification: .announcement, argument: text)
                                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                                    speakInIndonesian(text)
                                }
                            } else if let name = viewModel.detectedProductName, let date = viewModel.detectedExpiryDate {
                                finalAlertType = .bothDetected(name: name, date: date)
                                let text = NSLocalizedString("Hasil deteksi objek: \(name), \(date.formatted(date: .long, time: .omitted))", comment: "Both detected text")
                                UIAccessibility.post(notification: .announcement, argument: text)
                                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                                    speakInIndonesian(text)
                                }
                            } else {
                                finalAlertType = .partialDetected(name: viewModel.detectedProductName, date: viewModel.detectedExpiryDate)
                                let text = NSLocalizedString("Hasil deteksi objek: \(viewModel.detectedProductName ?? "data tidak ditemukan"), \(viewModel.detectedExpiryDate?.formatted(date: .long, time: .omitted) ?? "data tidak ditemukan")", comment: "Partial detected text")
                                UIAccessibility.post(notification: .announcement, argument: text)
                                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                                    speakInIndonesian(text)
                                }
                            }
                        }
                    )
                    .padding(.top, 20)
                }
                
                // Scanner Frame
                scannerFrameView
                    .frame(width: 280, height: 500)
                
                Spacer()
            }
            .padding()
            .background(
                NativeAlertController(finalAlertType: $finalAlertType, viewModel: viewModel)
            )
        }
        .alert(isPresented: $showGuidanceAlert) {
            Alert(
                title: Text(NSLocalizedString("Petunjuk Pemindaian", comment: "Guidance alert title")),
                message: Text(currentGuidanceText),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "Dismiss button"))) {
                    print("Guidance alert dismissed")
                    triggerSuccessHaptic()
                    showGuidanceAlert = false
                    refreshID = UUID() // Force preview refresh
                    // Check if scan failed
                    if viewModel.detectedProductName == nil && viewModel.detectedExpiryDate == nil {
                        showCustomAlert = true
                        let customText = NSLocalizedString("Silakan tahan posisi Anda dan putar item secara perlahan ke segala arah selama 10 detik saat proses pemindaian berlangsung", comment: "Custom alert text")
                        UIAccessibility.post(notification: .announcement, argument: customText)
                        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                            speakInIndonesian(customText)
                        }
                    }
                }
            )
        }
        .id(refreshID) // Force view refresh for preview
        .onAppear {
            let text = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuikan jarak hp dan barang yang ingin di scan", comment: "Initial guidance text")
            currentGuidanceText = text
            print("OnAppear: Setting guidance text: \(text)")
            // Delay to ensure preview renders alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showGuidanceAlert = true
                refreshID = UUID() // Force preview refresh
            }
            UIAccessibility.post(notification: .screenChanged, argument: text)
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.speakInIndonesian(text)
                    self.viewModel.startSession()
                }
            }
        }
    }
    
    // Custom Alert View
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
    
    // Scanner Frame
    private var scannerFrameView: some View {
        GeometryReader { geometry in
            let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round)
            let dashedStrokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, dash: [1, 2])
            let color = Color.white

            ZStack {
                // Corner Brackets
                CornerBracket(corner: .topLeft, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner: .topRight, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner: .bottomLeft, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner: .bottomRight, lineLength: 50).stroke(style: strokeStyle)

                // Dashed Lines
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width * 0.3, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: 0))
                }.stroke(style: dashedStrokeStyle)
                
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height))
                }.stroke(style: dashedStrokeStyle)
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.7))
                }.stroke(style: dashedStrokeStyle)
                
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.3))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.7))
                }.stroke(style: dashedStrokeStyle)
            }
            .foregroundColor(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("Object detection frame", comment: "Scanner frame accessibility label"))
        .accessibilityHint(NSLocalizedString("Position the item you want to scan inside this frame.", comment: "Scanner frame accessibility hint"))
    }
}

private struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    var viewModel: HomeViewModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            let placeholder = UIViewController()
            placeholder.view.backgroundColor = .gray
            return placeholder
        } else {
            return CameraViewController(viewModel: viewModel)
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    CameraView()
        .previewDisplayName("CameraView Preview")
}
