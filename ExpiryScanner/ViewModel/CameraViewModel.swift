//
//  CameraViewModel.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 09/06/25.
//

import AVFoundation
import Vision
import SwiftUI

@Observable
class CameraViewModel: NSObject,ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var showAlert = false
    var detectedProductName: String?
    var detectedExpiryDate: Date?
    var isProcessing = true
    var guidanceText = "Arahkan kamera ke produk"
    
    let captureSession = AVCaptureSession()
    private var visionRequest = [VNRequest]()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var detectedDateArea: CGRect?
    
    private var isProductInFrame = false {
        didSet {
            if oldValue != isProductInFrame {
                if isProductInFrame {
                    FeedbackManager.shared.startScanningFeedback()
                } else {
                    FeedbackManager.shared.stopScanningFeedback()
                }
            }
        }
    }
    
    override init() {
        super.init()
        setupVision()
    }
    
    func startSession(){
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.inputs.isEmpty {
                self.setupCaptureSession()
            }
            self.captureSession.startRunning()
            self.isProcessing = true
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self ] in
//            guard let self = self else { return }
            self?.isProductInFrame = false
            if self?.captureSession.isRunning ?? false {
                self?.captureSession.stopRunning()
            }
        }
    }
    
    private func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let deviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(deviceInput) else {
            print("Failed to setup camera")
            return
        }
        captureSession.addInput(deviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutputQueue"))
        if captureSession.canAddOutput(videoOutput){
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setupVision(){
        do {
            let productNameModel = try VNCoreMLModel(for: MedicineNameDetector().model)
            let productNameRequest = VNCoreMLRequest(model: productNameModel, completionHandler: handleProductNameDetection)
            productNameRequest.imageCropAndScaleOption = .centerCrop
            
            let expiryDateModel = try VNCoreMLModel(for: ExpiryDateDetector().model)
            let expiryDateRequest = VNCoreMLRequest(model: expiryDateModel, completionHandler: handleExpiryDateAreaDetection)
            expiryDateRequest.imageCropAndScaleOption = .scaleFill
            
            self.visionRequest = [productNameRequest, expiryDateRequest]
        } catch {
            fatalError("Failde to load model: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        guard isProcessing, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var request = self.visionRequest
        
        if let dateArea = self.detectedDateArea {
            let focusedTextRequest = VNRecognizeTextRequest(completionHandler: handleFocusedTextForDate)
            focusedTextRequest.recognitionLevel = .accurate
            focusedTextRequest.regionOfInterest = dateArea
            request.append(focusedTextRequest)
        }
    
        let orientation = getImageOrientation()
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation).perform(request)
    }
    
    private func getImageOrientation() -> CGImagePropertyOrientation {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }
    
    private func handleProductNameDetection(request: VNRequest, error: Error?){
        print("DEBUG: Product detection called")
        
        if let error = error {
            print("ERROR in product detection: \(error)")
            DispatchQueue.main.async {
                self.isProductInFrame = false
                self.guidanceText = "Error dalam deteksi produk"
            }
            return
        }
        
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            print("DEBUG: No observations found")
            DispatchQueue.main.async {
                self.isProductInFrame = false
                self.guidanceText = "Arahkan kamera ke produk"
            }
            return
        }
        
        print("DEBUG: Found \(observations.count) observations")
        
//        for (index, obs) in observations.enumerated() {
//            print("DEBUG: Observation \(index): confidence = \(obs.confidence), boundingBox = \(obs.boundingBox)")
//            print("DEBUG: Labels: \(obs.labels.map { "\($0.identifier): \($0.confidence)" })")
//        }
        
        let filteredResults = observations.filter { $0.confidence > 0.3 }
        
        guard let bestResult = filteredResults.first else {
            print("DEBUG: No results above confidence threshold")
            DispatchQueue.main.async {
                self.isProductInFrame = false
                self.guidanceText = "Arahkan kamera ke produk"
            }
            return
        }
        
        let productName = bestResult.labels.first?.identifier ?? "Unknown Product"
        let confidence = bestResult.confidence
        
        print("DEBUG: Best result - Product: \(productName), Confidence: \(confidence)")
        
        DispatchQueue.main.async {
            self.isProductInFrame = true
            self.detectedProductName = productName
            
            self.providePositionalGuidance(for: bestResult.boundingBox)
            
            self.checkForCompletion()
        }
    }
    
    private func providePositionalGuidance(for box: CGRect) {
        let area = box.width * box.height
        let centerX = box.midX
        
        if area < 0.15 {
            guidanceText = "Dekatkan sedikit"
        } else if area > 0.75 {
            guidanceText = "Jauhkan sedikit"
        } else if area < 0.3 {
            guidanceText = "Geser sedikit ke kanan"
        } else if area > 0.7 {
            guidanceText = "Geser sedikit ke kiri"
        } else {
            guidanceText = "Pertahankan posisi"
        }
    }
    
    private func handleExpiryDateAreaDetection(request: VNRequest, error: Error?){
        print("DEBUG: handleExpiryDateAreaDetection called")
        if let error = error {
            print("ERROR in area detection: \(error)")
        }
        
        let foundArea = (request.results as? [VNRecognizedObjectObservation])?.first?.boundingBox
        print("DEBUG: Found area: \(String(describing: foundArea))")
        
        DispatchQueue.main.async {
            self.detectedDateArea = foundArea
            self.guidanceText = (foundArea != nil) ? "Area tanggal terdeteksi, tahan posisi" : "Arahkan kamera ke produk"
        }
    }
    
    private func handleFocusedTextForDate(request: VNRequest, error: Error?){
        print("DEBUG: handleFocusedTextForDate called")
        if let error = error {
            print("ERROR in text recognition: \(error)")
        }
        
        let text = (request.results as? [VNRecognizedTextObservation] ?? []).compactMap { $0.topCandidates(1).first?.string}.joined(separator: " ")
        print("DEBUG: Recognized text: '\(text)'")
        
        if let date = DateParser.findDate(in: text){
            print("DEBUG: Parsed date: \(date)")
            DispatchQueue.main.async {
                self.detectedExpiryDate = date
                self.checkForCompletion()
            }
        } else {
            print("DEBUG: No date found in text")
        }
    }
    
    private func checkForCompletion(){
        // name blm masuk
        guard let productName = detectedProductName, let date = detectedExpiryDate else { return }
        
        isProcessing = false
        stopSession()
        
        FeedbackManager.shared.playHaptic(type: .success)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        let spokenDate = dateFormatter.string(from: date)
        
        let speechText = "\(productName) kadaluwarsa pada tanggal \(spokenDate)"
        FeedbackManager.shared.speak(text: speechText)
        
        showAlert = true
    }
    
    func resetDetection(){
        // nama produk
        detectedExpiryDate = nil
        detectedDateArea = nil
        showAlert = false
        startSession()
    }
}
