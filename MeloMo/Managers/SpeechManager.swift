// SpeechManager.swift — Speech-to-text via iOS Speech framework.
// On-device recognition by default (iOS 17+). No API key, no cost, works offline.
// Decision: AVAudioEngine over SFSpeechURLRecognitionRequest — real-time partial results.
import Speech
import SwiftUI

@MainActor
final class SpeechManager: ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false

    private let recognizer = SFSpeechRecognizer(locale: .current)
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()

    func startListening() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            Task { @MainActor in self?.beginSession() }
        }
    }

    func stopListening() {
        engine.stop()
        request?.endAudio()
        isListening = false
    }

    private func beginSession() {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true   // Update text in real-time as user speaks

        let node = engine.inputNode
        let fmt  = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in
            request.append(buf)
        }

        try? engine.start()
        isListening = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let text = result?.bestTranscription.formattedString {
                self?.transcript = text
            }
            if error != nil || result?.isFinal == true {
                self?.stopListening()
            }
        }
    }
}
