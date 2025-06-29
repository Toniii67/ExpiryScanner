import AVFoundation
import Vision
import SwiftUI
import CoreHaptics
import Combine

@MainActor
class HomeViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedProductName: String?
    @Published var detectedExpiryDate: Date?
    @Published var isProcessing = true
    @Published var guidanceText = "Posisikan hp di tengah dada"
    @Published var isSessionRunning = false
    @Published var stackDates: [Date] = []
    let showScanResultAlertSubject = PassthroughSubject<(name: String, date: Date), Never>()
    let showDoneAlertSubject = PassthroughSubject<Void, Never>()
    
    enum CustomHapticType {
        case success
        case error
        case fail
        case pulse
    }
    
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
            if oldValue != isProductInFrame {
                if isProductInFrame {
                    startScanningFeedback()
                } else {
                    stopScanningFeedback()
                }
            }
        }
    }
    
    override init() {
        super.init()
        setupVision()
        setupHaptics()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.inputs.isEmpty {
                self.setupCaptureSession()
            }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    self.isProcessing = true
                }
            }
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
    
    func toggleSession() {
        if isSessionRunning {
            stopSession()
        } else {
            startSession()
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
        } else if centerX < 0.3 {
            guidanceText = "Geser sedikit ke kanan"
        } else if centerX > 0.7 {
            guidanceText = "Geser sedikit ke kiri"
        } else {
            guidanceText = "Pertahankan posisi"
        }
    }
    
    private func handleExpiryDateAreaDetection(request: VNRequest, error: Error?) {
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
                        self.stackDates.append(date)
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
    
    func modeDate(from dates: [Date]) -> Date? {
        let counts = dates.reduce(into: [:]) { counts, date in
            counts[date, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
    
    private func checkForCompletion(){
        print("DEBUG: checkForCompletion called")
        
        if stackDates.count < 10 {
            print("DEBUG: Not enough dates to complete")
            return
        } else {
            print(stackDates)
        }
        
        if let mostCommonDate = modeDate(from: stackDates) {
            print("Most common date: \(mostCommonDate)")
            detectedExpiryDate = mostCommonDate
            stackDates = []
        }
        guard let productName = detectedProductName, let date = detectedExpiryDate else { return }
        
        isProcessing = false
        stopSession()
        playHaptic(type: .success)
        
        showScanResultAlertSubject.send((name: productName, date: date))
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        let spokenDate = dateFormatter.string(from: date)
    }
    
    func resetDetection() {
        detectedProductName = nil
        detectedExpiryDate = nil
        detectedDateArea = nil
        stackDates = []
        isProcessing = true
        startSession()
    }
    
    func markAsDone() {
        showDoneAlertSubject.send()
        playHaptic(type: .success)
    }
    
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
    
    func playHaptic(type: CustomHapticType) {
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
            return try CHHapticPattern(events: [event], parameters: [])
            
        case .error:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.15)
            return try CHHapticPattern(events: [event1, event2], parameters: [])
            
        case .fail:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
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
}

