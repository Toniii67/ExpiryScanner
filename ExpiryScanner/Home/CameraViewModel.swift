//
//  CameraViewModel.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 09/06/25.
//


// cobacoba

import AVFoundation
import Vision
import SwiftUI
import CoreHaptics

@Observable
class CameraViewModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Published Properties
    var showAlert = false
    var detectedProductName: String?
    var detectedExpiryDate: Date?
    var isProcessing = true
    var guidanceText = "Arahkan kamera ke produk"
    var isSessionRunning = false
    
    // MARK: - Haptic Enum
    enum CustomHapticType {
        case success
        case error
        case fail
        case pulse
    }
    
    // MARK: - Private Properties
    let captureSession = AVCaptureSession()
    private var visionRequest = [VNRequest]()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var hapticEngine: CHHapticEngine?
    private var detectedDateArea: CGRect?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var continuousScanningTimer: Timer?
    
    
    private var isProductInFrame = false {
        didSet {
            // This now correctly calls the methods inside this ViewModel
            if oldValue != isProductInFrame {
                if isProductInFrame {
                    startScanningFeedback()
                } else {
                    stopScanningFeedback()
                }
            }
        }
    }
    
    // MARK: - Initializer
    override init() {
        super.init()
        setupVision()
        setupHaptics()
    }
    
    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.inputs.isEmpty {
                self.setupCaptureSession()
            }
            
            // CORRECTED LOGIC: Start only if it's NOT running.
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
            self.isProcessing = true
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isProductInFrame = false
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    /// Toggles the camera session on or off based on its current state.
    func toggleSession() {
        if isSessionRunning {
            stopSession()
        } else {
            startSession()
        }
    }
    
    // MARK: - Setup Methods
    private func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let deviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(deviceInput) else {
            print("Failed to setup camera")
            return
        }
        captureSession.addInput(deviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutputQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setupVision() {
        do {
            let productNameModel = try VNCoreMLModel(for: MedicineNameDetector().model)
            let productNameRequest = VNCoreMLRequest(model: productNameModel, completionHandler: handleProductNameDetection)
            productNameRequest.imageCropAndScaleOption = .centerCrop
            
            let expiryDateModel = try VNCoreMLModel(for: ExpiryDateDetector().model)
            let expiryDateRequest = VNCoreMLRequest(model: expiryDateModel, completionHandler: handleExpiryDateAreaDetection)
            expiryDateRequest.imageCropAndScaleOption = .scaleFill
            
            self.visionRequest = [productNameRequest, expiryDateRequest]
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }
    
    // MARK: - Vision Handlers & Logic
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isProcessing, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var request = self.visionRequest
        
        let focusedTextRequest = VNRecognizeTextRequest(completionHandler: handleFocusedTextForDate)
        focusedTextRequest.recognitionLevel = .accurate

        if let dateArea = self.detectedDateArea {
            focusedTextRequest.regionOfInterest = dateArea
        } else {
            focusedTextRequest.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1) // full frame
        }
    
        request.append(focusedTextRequest)

    
        let orientation = getImageOrientation()
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation).perform(request)
    }
    
    
    private func getImageOrientation() -> CGImagePropertyOrientation {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait: return .right
        case .portraitUpsideDown: return .left
        case .landscapeLeft: return .up
        case .landscapeRight: return .down
        default: return .right
        }
    }
    
    // MARK: - Vision Handlers
    private func handleProductNameDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("ERROR in product detection: \(error)")
            playHaptic(type: .error)
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
            playHaptic(type: .error)
        }
        
        let foundArea = (request.results as? [VNRecognizedObjectObservation])?.first?.boundingBox
        print("DEBUG: Found area: \(String(describing: foundArea))")
        
        DispatchQueue.main.async {
            self.detectedDateArea = foundArea
            self.guidanceText = (foundArea != nil) ? "Area tanggal terdeteksi, tahan posisi" : "Arahkan kamera ke produk"
        }
    }
    
    private func handleFocusedTextForDate(request: VNRequest, error: Error?) {
        print("DEBUG: handleFocusedTextForDate called")

        if let error = error {
            print("ERROR in text recognition: \(error)")
            return
        }

        let recognizedText = (request.results as? [VNRecognizedTextObservation] ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        
        print("DEBUG: Recognized text: '\(recognizedText)'")

        classifyText(recognizedText)
    }

    private func classifyText(_ text: String) {
        print("DEBUG: Classifying text: '\(text)'")
        
        do {
            let model = try MyTextClassifier(configuration: MLModelConfiguration())
            let prediction = try model.prediction(text: text)
            print("DEBUG: Classification result: \(prediction.label)")
            guard text.count > 8 else {
                print("DEBUG: Skipping classification - text too short")
                return
            }
            
            switch prediction.label {
            case "expiry","both":
                if let date = DateParserAdvanced.findDate(in: text) {
                    print("DEBUG: Parsed expiry date: \(date)")
                    DispatchQueue.main.async {
                        self.detectedExpiryDate = date
                        self.checkForCompletion()
                    }
                }
            default:
                print("DEBUG: No expiry info found")
            }
        } catch {
            print("ERROR: Failed to classify text - \(error)")
        }
    }


    private func checkForCompletion(){
        print("DEBUG: checkForCompletion called")
        guard let productName = detectedProductName, let date = detectedExpiryDate else { return }
        
        isProcessing = false
        stopSession()
        playHaptic(type: .success)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        let spokenDate = dateFormatter.string(from: date)
        
        let speechText = "\(productName) kadaluwarsa pada tanggal \(spokenDate)"
        speak(text: speechText) // Use the internal speak method
        
        showAlert = true
    }
    
    func resetDetection(){
        // nama produk
        detectedExpiryDate = nil
        detectedDateArea = nil
        showAlert = false
        startSession()
    }
    
    // MARK: - Haptic Feedback Implementation
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            hapticEngine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                try? self?.hapticEngine?.start()
            }
        } catch {
            print("Haptic engine failed to start: \(error.localizedDescription)")
        }
    }
    
    private func playHaptic(type: CustomHapticType) {
        guard let hapticEngine = hapticEngine else { return }
        
        do {
            let pattern = try hapticPattern(for: type)
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play custom haptic of type \(type): \(error.localizedDescription)")
        }
    }
    
    private func hapticPattern(for type: CustomHapticType) throws -> CHHapticPattern {
        switch type {
        case .success:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            // CORRECTED: Pass an empty array
            return try CHHapticPattern(events: [event], parameters: [])
            
        case .error:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.15)
            // CORRECTED: Pass an empty array
            return try CHHapticPattern(events: [event1, event2], parameters: [])
            
        case .fail:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            // CORRECTED: Pass parameters inside the event initializer
            let continuousEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.4
            )
            return try CHHapticPattern(events: [continuousEvent], parameters: [])
            
        case .pulse:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            return try CHHapticPattern(events: [event], parameters: [])
        }
    }
    
    private func startScanningFeedback() {
        stopScanningFeedback()
        continuousScanningTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.playHaptic(type: .pulse)
        }
    }
    
    private func stopScanningFeedback() {
        continuousScanningTimer?.invalidate()
        continuousScanningTimer = nil
    }
    // MARK: - Speech Synthesis
    private func speak(text: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Could not configure audio session for speech: \(error.localizedDescription)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        speechSynthesizer.speak(utterance)
    }
}

