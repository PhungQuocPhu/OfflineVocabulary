import Foundation
import Speech
import AVFoundation

class SpeechRecognizerHelper: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String? = nil

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        requestSpeechAuthorization()
    }

    // Xin quyền nhận diện giọng nói
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    break
                case .denied:
                    self.errorMessage = "Bạn đã từ chối quyền nhận diện giọng nói."
                case .restricted, .notDetermined:
                    self.errorMessage = "Thiết bị không hỗ trợ nhận diện giọng nói."
                @unknown default:
                    self.errorMessage = "Lỗi không xác định khi xin quyền."
                }
            }
        }
    }

    func startRecording() {
        transcript = ""
        errorMessage = nil

        // Kiểm tra quyền speech
        if SFSpeechRecognizer.authorizationStatus() != .authorized {
            requestSpeechAuthorization()
            self.errorMessage = "Chưa được cấp quyền nhận diện giọng nói."
            return
        }

        // Kiểm tra quyền micro
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.errorMessage = "Bạn chưa cấp quyền micro cho ứng dụng."
                    return
                }
                self._startRecordingImpl()
            }
        }
    }

    private func _startRecordingImpl() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = "Không thiết lập được audio session: \(error.localizedDescription)"
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            self.errorMessage = "Không khởi tạo được request nhận diện."
            return
        }
        request.shouldReportPartialResults = true

        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0) // Đảm bảo không bị tap trùng
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.errorMessage = "Không thể bắt đầu ghi âm: \(error.localizedDescription)"
            return
        }
        isRecording = true

        recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Lỗi nhận diện: \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }

    func reset() {
        stopRecording()
        transcript = ""
        errorMessage = nil
    }
}
