//
//  FeedbackManager.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 11/06/25.
//

import AVFoundation
import CoreHaptics
import UIKit

class FeedbackManager {
    static let shared = FeedbackManager()
    
    private var hapticEngine: CHHapticEngine?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupHaptics()
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
    func startScanningFeedback(){
        
    }
    
    func stopScanningFeedback(){
        
    }
    
    func playHaptic(type: UINotificationFeedbackGenerator.FeedbackType){
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    func playSound(named name: String){
        
    }
    
    func speak(text: String){
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
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
