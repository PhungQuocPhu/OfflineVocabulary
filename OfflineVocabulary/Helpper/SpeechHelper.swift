import AVFoundation

class SpeechHelper {
    static let shared = SpeechHelper()
    private let synthesizer = AVSpeechSynthesizer()

    func speakEnglish(text: String) {
        // Nếu đang nói thì dừng lại để nói từ mới luôn
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
