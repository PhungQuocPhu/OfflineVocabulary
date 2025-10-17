import SwiftUI
import AVFoundation

struct SpeakingPracticeView: View {
    let allTopics: [VocabTopic]
    @State private var selectedIDs: Set<UUID> = []
    @State private var flashcards: [VocabItem] = []
    @State private var currentIndex: Int = 0
    @State private var isPracticing: Bool = false

    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var matchPercent: Int = 0
    @State private var showResult = false

    // UI: để tránh bấm liên tục nút ghi âm
    @State private var canRecord = true

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationView {
            if !isPracticing {
                Form {
                    Section(header: Text("Chọn chủ đề luyện nói")) {
                        List(allTopics, id: \.id, selection: $selectedIDs) { topic in
                            HStack {
                                Text(topic.title)
                                Spacer()
                                if selectedIDs.contains(topic.id) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle").foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedIDs.contains(topic.id) {
                                    selectedIDs.remove(topic.id)
                                } else {
                                    selectedIDs.insert(topic.id)
                                }
                            }
                        }
                        .frame(height: min(300, CGFloat(allTopics.count) * 48 + 40))
                    }
                    Section {
                        Button("Bắt đầu luyện nói") {
                            let selectedTopics = allTopics.filter { selectedIDs.contains($0.id) }
                            flashcards = selectedTopics
                                .flatMap { $0.items }
                                .shuffled()
                            currentIndex = 0
                            isPracticing = true
                            showResult = false
                            matchPercent = 0
                        }
                        .disabled(selectedIDs.isEmpty)
                    }
                }
                .navigationTitle("Luyện nói (Shadowing)")
            } else {
                VStack(spacing: 18) {
                    if flashcards.indices.contains(currentIndex) {
                        let card = flashcards[currentIndex]
                        Text(card.word)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                        if let example = card.example, !example.isEmpty {
                            Text(example)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        // Waveform hiển thị khi đang ghi âm
                        if speechManager.isRecording {
                            WaveformView(samples: speechManager.waveformSamples)
                                .frame(height: 40)
                                .padding(.vertical, 4)
                        }

                        Button(action: { speak(card.example ?? card.word) }) {
                            Label("Nghe phát âm", systemImage: "speaker.wave.2.fill")
                        }
                        .padding(.vertical, 6)
                        .disabled(speechManager.isRecording)
                        .opacity(speechManager.isRecording ? 0.3 : 1)

                        Button(action: {
                            startShadowingRecording()
                        }) {
                            if speechManager.isRecording {
                                Label("Đang ghi âm...", systemImage: "mic.circle.fill")
                                    .foregroundColor(.red)
                            } else {
                                Label("Bắt đầu ghi âm", systemImage: "mic.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.title2)
                        .disabled(speechManager.isRecording || !canRecord)

                        if let error = speechManager.recognitionError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }

                        if showResult {
                            if speechManager.recognizedText.isEmpty {
                                Text("Không nhận diện được âm thanh. Hãy thử lại!")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                Text("Độ khớp: 0%")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("CHƯA ĐẠT 😅")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            } else {
                                Text("Bạn phát âm: '\(speechManager.recognizedText)'")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Độ khớp: \(matchPercent)%")
                                    .font(.headline)
                                    .foregroundColor(matchPercent > 80 ? .green : .orange)
                                if matchPercent > 80 {
                                    Text("ĐẠT 🎉")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                } else {
                                    Text("CHƯA ĐẠT 😅")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                            }
                        }

                        Button(currentIndex < flashcards.count-1 ? "Tiếp theo" : "Kết thúc") {
                            nextCard()
                        }
                        .disabled(speechManager.isRecording)
                        .padding(.top, 10)
                    } else {
                        Text("Hoàn thành luyện nói!")
                            .font(.title)
                            .foregroundColor(.blue)
                        Button("Luyện lại") {
                            isPracticing = false
                            selectedIDs = []
                            showResult = false
                            matchPercent = 0
                        }
                        .padding(.top)
                    }
                }
                .padding()
                .navigationTitle("Luyện nói")
                .navigationBarItems(leading: Button("Quay lại") {
                    isPracticing = false
                    selectedIDs = []
                    showResult = false
                    matchPercent = 0
                })
            }
        }
        .onDisappear {
            speechManager.stopRecording()
        }
    }

    func nextCard() {
        showResult = false
        speechManager.recognizedText = ""
        matchPercent = 0
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
        } else {
            currentIndex += 1
        }
    }

    func speak(_ text: String) {
        if speechManager.isRecording {
            speechManager.stopRecording()
        }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func startShadowingRecording() {
        showResult = false
        speechManager.recognizedText = ""
        matchPercent = 0
        canRecord = false

        speechManager.startRecording {
            compareText()
            showResult = true
            // Đợi 1.5s sau khi stop mới enable lại nút ghi âm
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                canRecord = true
            }
        }
    }

    func compareText() {
        guard flashcards.indices.contains(currentIndex) else { return }
        let target = flashcards[currentIndex].word
        let spoken = speechManager.recognizedText
        matchPercent = similarityPercent(target, spoken)
    }
}
