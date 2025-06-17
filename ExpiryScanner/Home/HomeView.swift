//
//  HomeView.swift
//  ExpiryScanner
//
//  Created by Victor Chandra on 16/06/25.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            CameraViewControllerRepresentable(viewModel: viewModel)
               .ignoresSafeArea()
            
            VStack {
                Spacer()
                //Buat Frame Bracket
                scannerFrameView
                   .frame(width: 280, height: 500)
                   .padding(.bottom, 20)
                
                Text(viewModel.guidanceText)
                   .font(.headline)
                   .foregroundColor(.white)
                   .padding()
                   .background(Color.black.opacity(0.6))
                   .clipShape(Capsule())
                   .padding(.top)
                
                Spacer()
                
                // New instructional text from the design.
                Text("Tombol mulai terletak di bawah screen")
                   .font(.body)
                   .fontWeight(.bold)
                   .foregroundColor(.red)
                   .multilineTextAlignment(.center)
                   .padding(.top, 20)
                   .padding(.bottom, 20)
                
                // New "Stop Scanning" button from the design.
                Button(action: {
                    viewModel.toggleSession()
                }) {
                    Text(viewModel.isSessionRunning ? "Stop Scanning" : "Start Scanning")
                       .font(.headline)
                       .fontWeight(.bold)
                       .foregroundColor(.primary)
                       .padding()
                       .frame(maxWidth:.infinity)
                       .background(.thinMaterial)
                       .clipShape(Capsule())
                }
               .padding(.horizontal, 40)
               .padding(.bottom, 30)
            }
           .padding()
        }
        
        Spacer()
        
       .onAppear{
            let text = "Arahkan kamera ke produk"
            UIAccessibility.post(notification:.screenChanged, argument: text)
        }
       .alert("Hasil Pemindaian", isPresented: $viewModel.showAlert){
            Button("Pindai lagi"){
                viewModel.resetDetection()
            }
        } message: {
            if let date = viewModel.detectedExpiryDate, let name = viewModel.detectedProductName {
                Text("\(name) Kadaluwarsa pada \(date.formatted(date:.long, time:.omitted))")
            }
        }
    }
    
    /// A private computed property that builds the custom scanner frame.
    private var scannerFrameView: some View {
        GeometryReader { geometry in
            let strokeStyle = StrokeStyle(lineWidth: 10, lineCap:.round)
            let dashedStrokeStyle = StrokeStyle(lineWidth: 10, lineCap:.round, dash: [1, 2])
            let color = Color.white

            ZStack {
                // Corner Brackets
                CornerBracket(corner:.topLeft, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner:.topRight, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner:.bottomLeft, lineLength: 50).stroke(style: strokeStyle)
                CornerBracket(corner:.bottomRight, lineLength: 50).stroke(style: strokeStyle)

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
       .accessibilityElement(children:.combine)
       .accessibilityLabel("Object detection frame")
       .accessibilityHint("Position the item you want to scan inside this frame.")
    }
}

private struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
//    @ObservedObject
    var viewModel: CameraViewModel
    
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

#Preview {
    HomeView()
}
