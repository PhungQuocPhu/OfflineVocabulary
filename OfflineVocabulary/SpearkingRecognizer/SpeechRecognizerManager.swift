import Foundation
import Speech
import AVFoundation
import Accelerate

class SpeechRecognizerManager: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording = false
    @Published var permissionGranted = false
    @Published var recognitionError: String? = nil
    @Published var waveformSamples: [Float] = []

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN")) // Đổi ngôn ngữ nếu cần
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var silenceTimer: Timer?
    private var maxWaitTimer: Timer?
    private var latestSpeechTime: Date?
    private var firstSpeechTime: Date?
    private var everDetectedSpeech = false
    private let silenceThreshold: Float = -60

    override init() {
        super.init()
        requestPermissions()
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.permissionGranted = (authStatus == .authorized)
                if authStatus != .authorized {
                    self.recognitionError = "Bạn chưa cấp quyền Nhận diện giọng nói cho ứng dụng."
                }
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                self.permissionGranted = self.permissionGranted && allowed
                if !allowed {
                    self.recognitionError = "Bạn chưa cấp quyền Micro cho ứng dụng."
                }
            }
        }
    }

    private func cleanupAudio() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxWaitTimer?.invalidate()
        maxWaitTimer = nil
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
            engine.reset()
            audioEngine = nil
        }
        request?.endAudio()
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        waveformSamples = []
    }

    func startRecording(completion: (() -> Void)? = nil) {
        guard permissionGranted else {
            self.recognitionError = "Chưa cấp quyền truy cập micro và nhận diện tiếng nói."
            return
        }
        cleanupAudio()
        self.recognitionError = nil
        self.recognizedText = ""
        everDetectedSpeech = false
        latestSpeechTime = nil
        firstSpeechTime = nil

        let engine = AVAudioEngine()
        self.audioEngine = engine
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.recognitionError = "Lỗi thiết lập AudioSession: \(error.localizedDescription)"
            cleanupAudio()
            return
        }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        if inputFormat.sampleRate == 0 || inputFormat.channelCount == 0 {
            self.recognitionError = "Thiết bị không truy cập được micro. Vui lòng khởi động lại máy."
            cleanupAudio()
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            self.request?.append(buffer)
            guard let channelData = buffer.floatChannelData else { return }
            let channelDataValue = channelData[0]
            let frameLength = Int(buffer.frameLength)

            // Lấy waveform (lấy 64 điểm/ngưỡng) và khuếch đại
            var samples: [Float] = []
            let step = max(frameLength / 64, 1)
            for i in stride(from: 0, to: frameLength, by: step) {
                let amplified = max(-1, min(1, channelDataValue[i] * 4))
                samples.append(amplified)
            }
            DispatchQueue.main.async {
                self.waveformSamples = samples
            }

            // Đo avg power và peak để nhận diện nói (nhạy vừa phải)
            var sum: Float = 0
            vDSP_meamgv(channelDataValue, 1, &sum, vDSP_Length(frameLength))
            let avgPower = 20 * log10(sum)
            let samplesArray = Array(UnsafeBufferPointer(start: channelDataValue, count: frameLength))
            let peak = samplesArray.map { abs($0) }.max() ?? 0
            if avgPower > self.silenceThreshold || peak > 0.01 {
                self.latestSpeechTime = Date()
                if self.firstSpeechTime == nil {
                    self.firstSpeechTime = self.latestSpeechTime
                }
                self.everDetectedSpeech = true
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            self.recognitionError = "Không khởi động được audio engine: \(error.localizedDescription)"
            cleanupAudio()
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                print("recognizedText partial: \(result.bestTranscription.formattedString) isFinal: \(result.isFinal)")
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.stopRecording()
                        completion?()
                    }
                    return
                }
            }
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.stopRecording()
                    completion?()
                }
            }
        }

        isRecording = true

        // Timer kiểm tra im lặng 2s sau khi đã phát hiện nói, chỉ cho phép stop nếu đã nói được > 1s
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.everDetectedSpeech, let last = self.latestSpeechTime, let first = self.firstSpeechTime {
                let elapsed = Date().timeIntervalSince(last)
                let duration = Date().timeIntervalSince(first)
                if elapsed > 2.0 && duration > 1.0 {
                    self.stopRecording()
                    completion?()
                }
            }
        }

        // Timer 4s nếu không phát hiện tiếng nói
        maxWaitTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.everDetectedSpeech {
                self.recognitionError = "Không phát hiện âm thanh, vui lòng thử lại!"
                self.stopRecording()
                completion?()
            }
        }
    }

    func stopRecording() {
        cleanupAudio()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: [.notifyOthersOnDeactivation])
    }
}
