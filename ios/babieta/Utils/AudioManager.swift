//
//  AudioManager.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import Foundation
import AVFoundation
import SwiftUI
import AudioToolbox

class AudioManager: NSObject, ObservableObject {
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    @Published var isSpeaking = false
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    func speak(text: String, language: String = "ru-RU") {
        guard !text.isEmpty else { return }
        
        // 停止当前播放
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8 // 稍微慢一点
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    func playSuccess() {
        // 播放系统音效
        #if os(iOS)
        AudioServicesPlaySystemSound(1016) // 键盘点击音效
        #endif
    }
    
    func playVictory() {
        // 播放激昂的获胜音效
        #if os(iOS)
        AudioServicesPlaySystemSound(1013) // 更激昂的音效
        #endif
    }
    
    func playError() {
        // 播放错误音效
        #if os(iOS)
        AudioServicesPlaySystemSound(1053) // 错误音效
        #endif
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AudioManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
