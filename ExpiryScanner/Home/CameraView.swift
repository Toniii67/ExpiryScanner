//
//  CameraView.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 09/06/25.
//

import SwiftUI

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            CameraViewControllerRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack{
                Text(viewModel.guidanceText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.top)
                
                Spacer()
            }
        }
        .onAppear{
            let text = "Arahkan kamera ke produk"
            UIAccessibility.post(notification: .screenChanged, argument: text)
            FeedbackManager.shared.speak(text: text)
        }
        .alert("Hasil Pemindaian", isPresented: $viewModel.showAlert){
            Button("Pindai lagi"){
                viewModel.resetDetection()
            }
        } message: {
            // data nama produk belum dimasukkan
            if let date = viewModel.detectedExpiryDate, let name = viewModel.detectedProductName {
                Text("\(name) Kadaluwarsa pada \(date.formatted(date: .long, time: .omitted))")
            }
        }
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
    CameraView()
}
