import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showGuidanceText = true
    @State private var showStatusPopup = false
    @State private var currentGuidanceText = "Posisikan hp di tengah dada"
    @State private var guidanceLoopCount = 0
    @State private var statusLoopCount = 0
    @AccessibilityFocusState private var focusStatusPopup: Bool
    
    // Function to trigger success haptic feedback
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    var body: some View {
        ZStack {
            CameraViewControllerRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                // Guidance Text (at top)
                if showGuidanceText {
                    Text(currentGuidanceText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        .accessibilityLabel(currentGuidanceText)
                        .accessibilityHint("Petunjuk pemindaian saat ini")
                        .accessibilityAddTraits(.isStaticText)
                        .onAppear {
                            // Handled in .onAppear and .onChange
                        }
                }
                
                // Status Pop-Up (at top, replacing guidance text)
                if showStatusPopup {
                    Text("Pastikan hanya satu produk yang terdeteksi")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        .accessibilityLabel("Pastikan hanya satu produk yang terdeteksi")
                        .accessibilityHint("Status pemindaian saat ini")
                        .accessibilityAddTraits(.isStaticText)
                        .accessibilityFocused($focusStatusPopup)
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
                    title: "Hasil Pemindaian",
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
        .onAppear {
            let text = "Posisikan hp di tengah dada"
            currentGuidanceText = text
            showGuidanceText = true
            showStatusPopup = false
            guidanceLoopCount = 0
            statusLoopCount = 0
            UIAccessibility.post(notification: .screenChanged, argument: text)
            viewModel.speak(text: text)
            viewModel.startSession()
            
            // Loop guidance text twice (5 seconds each)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if guidanceLoopCount < 1 {
                    guidanceLoopCount += 1
                    showGuidanceText = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showGuidanceText = true
                        UIAccessibility.post(notification: .announcement, argument: text)
                        viewModel.speak(text: text)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showGuidanceText = false
                        triggerSuccessHaptic() // Haptic for guidance completion
                        // Start status pop-up looping
                        showStatusPopup = true
                        focusStatusPopup = true
                        statusLoopCount = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let statusText = "Pastikan hanya satu produk yang terdeteksi"
                            UIAccessibility.post(notification: .announcement, argument: statusText)
                            UIAccessibility.post(notification: .layoutChanged, argument: statusText)
                            viewModel.speak(text: statusText)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            if statusLoopCount < 1 {
                                statusLoopCount += 1
                                showStatusPopup = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showStatusPopup = true
                                    focusStatusPopup = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        let statusText = "Pastikan hanya satu produk yang terdeteksi"
                                        UIAccessibility.post(notification: .announcement, argument: statusText)
                                        UIAccessibility.post(notification: .layoutChanged, argument: statusText)
                                        viewModel.speak(text: statusText)
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    showStatusPopup = false
                                    triggerSuccessHaptic() // Haptic for status completion
                                }
                            } else {
                                showStatusPopup = false
                                triggerSuccessHaptic() // Haptic for status completion
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.guidanceText) { newText in
            currentGuidanceText = newText
            showGuidanceText = true
            showStatusPopup = false
            statusLoopCount = 0
            UIAccessibility.post(notification: .announcement, argument: newText)
            viewModel.speak(text: newText)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                showGuidanceText = false
                triggerSuccessHaptic() // Haptic for guidance completion
                showStatusPopup = true
                focusStatusPopup = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let statusText = "Pastikan hanya satu produk yang terdeteksi"
                    UIAccessibility.post(notification: .announcement, argument: statusText)
                    UIAccessibility.post(notification: .layoutChanged, argument: statusText)
                    viewModel.speak(text: statusText)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if statusLoopCount < 1 {
                        statusLoopCount += 1
                        showStatusPopup = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showStatusPopup = true
                            focusStatusPopup = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                let statusText = "Pastikan hanya satu produk yang terdeteksi"
                                UIAccessibility.post(notification: .announcement, argument: statusText)
                                UIAccessibility.post(notification: .layoutChanged, argument: statusText)
                                viewModel.speak(text: statusText)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            showStatusPopup = false
                            triggerSuccessHaptic() // Haptic for status completion
                        }
                    } else {
                        showStatusPopup = false
                        triggerSuccessHaptic() // Haptic for status completion
                    }
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
        .accessibilityLabel("Object detection frame")
        .accessibilityHint("Position the item you want to scan inside this frame.")
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
