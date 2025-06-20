import SwiftUI
import UIKit
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showCustomAlert = false

    // Alert state
    @State private var showUIKitAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertActions: [UIAlertAction] = []

    var body: some View {
        ZStack {
            CameraViewControllerRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

            VStack {
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

                scannerFrameView
                    .frame(width: 280, height: 500)

                Spacer()
            }
            .padding()

            if showUIKitAlert {
                UIKitAlertController(
                    title: alertTitle,
                    message: alertMessage,
                    actions: alertActions
                )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                alertTitle = NSLocalizedString("Petunjuk Pemindaian", comment: "")
                alertMessage = NSLocalizedString("Letakan hp di tengah dada dan hanya 1 barang di depan camera anda untuk hasil terbaik. Sesuaikan jarak hp dan barang yang ingin di scan", comment: "")
                alertActions = [
                    UIAlertAction(title: "OK", style: .default) { _ in
                        
                    }
                ]
                showUIKitAlert = true
                viewModel.startSession()
            }
        }
        .onReceive(viewModel.showScanResultAlertSubject) { data in
            alertTitle = "Hasil Pemindaian"
            alertMessage = "\(data.name) kadaluwarsa pada \(data.date.formatted(date: .long, time: .omitted))"
            alertActions = [
                UIAlertAction(title: "Pindai Lagi", style: .default) { _ in
                    viewModel.resetDetection()
                },
                UIAlertAction(title: "Selesai", style: .default) { _ in
                    viewModel.markAsDone()
                }
            ]
            showUIKitAlert = true
        }
        .onReceive(viewModel.showDoneAlertSubject) { _ in
            alertTitle = "Pemindaian Selesai"
            alertMessage = ""
            alertActions = [
                UIAlertAction(title: "OK", style: .default) { _ in }
            ]
            showUIKitAlert = true
        }
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private var scannerFrameView: some View {
        GeometryReader { geometry in
            let strokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round)
            let dashedStrokeStyle = StrokeStyle(lineWidth: 10, lineCap: .round, dash: [1, 2])
            let color = Color.white

            ZStack {
                CornerBracket(corner: .topLeft, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner: .topRight, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner: .bottomLeft, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner: .bottomRight, lineLength: 50).stroke(style: strokeStyle)

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
