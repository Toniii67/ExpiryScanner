import SwiftUI
import UIKit
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var currentAlert: AlertType? = nil
    @State private var currentGuidanceText = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuikan jarak hp dan barang yang ingin di scan", comment: "Initial guidance text")
    @State private var showCustomAlert: Bool = false
    
    enum AlertType: Identifiable {
        case guidance
        
        var id: String {
            "guidance"
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
            CameraViewControllerRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                // Custom Alert
                if showCustomAlert {
                    CustomAlertView(
                        text: NSLocalizedString("Silakan tahan posisi Anda dan putar item secara perlahan ke segala arah selama 10 detik saat proses pemindaian berlangsung", comment: "Custom alert text"),
                        onDismiss: {
                            triggerSuccessHaptic()
                            showCustomAlert = false
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
                NativeAlertController(
                    isPresented: $viewModel.showAlert,
                    showDoneAlert: $viewModel.showDoneAlert,
                    title: NSLocalizedString("Hasil Pemindaian", comment: "Scan result title"),
                    message: {
                        if let date = viewModel.detectedExpiryDate, let name = viewModel.detectedProductName {
                            return "\(name) Kadaluwarsa pada \(date.formatted(date: .long, time: .omitted))"
                        }
                        return nil
                    }(),
                    viewModel: viewModel
                )
            )
        }
        .alert(item: $currentAlert) { _ in
            Alert(
                title: Text(NSLocalizedString("Petunjuk Pemindaian", comment: "Guidance alert title")),
                message: Text(currentGuidanceText),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "Dismiss button"))) {
                    print("Guidance alert dismissed")
                    triggerSuccessHaptic()
                    currentAlert = nil
                    // Check if scan failed
                    if viewModel.detectedProductName == nil && viewModel.detectedExpiryDate == nil {
                        showCustomAlert = true
                        let customText = NSLocalizedString("Silakan tahan posisi Anda dan putar item secara perlahan ke segala arah selama 10 detik saat proses pemindaian berlangsung", comment: "Custom alert text")
                        UIAccessibility.post(notification: .announcement, argument: customText)
                        speakInIndonesian(customText)
                    }
                }
            )
        }
        .onAppear {
            let text = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuikan jarak hp dan barang yang ingin di scan", comment: "Initial guidance text")
            currentGuidanceText = text
            print("Setting initial guidance: \(text)")
            // Delay to ensure view initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentAlert = .guidance
                UIAccessibility.post(notification: .screenChanged, argument: text)
                speakInIndonesian(text)
            }
            viewModel.startSession()
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
    
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

#Preview {
    HomeView()
}
