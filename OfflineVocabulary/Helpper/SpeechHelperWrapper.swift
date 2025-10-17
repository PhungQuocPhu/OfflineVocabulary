import Foundation
import AVFoundation

class SpeechHelperWrapper: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentLoopId: UUID?
    private var repeatCondition: (() -> Bool)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speakEnglish(text: String) {
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    /// Lặp lại phát âm khi repeatCondition trả về true (truyền id để tránh lặp nhầm từ)
    func loopSpeak(text: String, id: UUID, repeatCondition: @escaping () -> Bool) {
        stopSpeaking()
        currentLoopId = id
        self.repeatCondition = repeatCondition
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        currentLoopId = nil
        repeatCondition = nil
    }
}

extension SpeechHelperWrapper: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let shouldRepeat = repeatCondition, shouldRepeat() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let text = utterance.speechString as String?, self.currentLoopId != nil {
                    let utter = AVSpeechUtterance(string: text)
                    utter.voice = AVSpeechSynthesisVoice(language: "en-US")
                    self.synthesizer.speak(utter)
                }
            }
        }
    }
}
