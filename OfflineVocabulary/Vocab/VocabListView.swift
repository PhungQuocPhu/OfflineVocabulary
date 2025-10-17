import SwiftUI

struct VocabListView: View {
    @State var topic: VocabTopic
    var allTopics: [VocabTopic]
    var onUpdate: (VocabTopic) -> Void
    var onUpdateAllTopics: ([VocabTopic]) -> Void

    @State private var showAddWord = false
    @State private var selectedItem: VocabItem? = nil
    @State private var isSelecting = false
    @State private var selectedItems = Set<UUID>()
    @State private var showCopySheet = false
    @State private var showRenameAlert = false
    @State private var newTopicName = ""

    // --- Phát âm liên tục ---
    @State private var isContinuousMode: Bool = false
    @State private var loopingWordId: UUID? = nil
    @StateObject private var speechHelper = SpeechHelperWrapper()
    @State private var speakingWordId: UUID? = nil   // trạng thái cho hiệu ứng phát âm 1 lần

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(topic.title)
                    .font(.system(size: 26, weight: .bold))
                Spacer()
                Button(action: {
                    newTopicName = topic.title
                    showRenameAlert = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.orange)
                        .imageScale(.large)
                }
                .accessibilityLabel("Đổi tên chủ đề")
                Button(action: { showAddWord = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.top, 18)

            // Toolbar chọn/copy nhiều từ + nút phát liên tục
            HStack {
                if isSelecting {
                    Button("Huỷ chọn") {
                        selectedItems.removeAll()
                        isSelecting = false
                    }
                    Spacer()
                    Text("\(selectedItems.count) đã chọn")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    if selectedItems.count > 0 {
                        Button {
                            showCopySheet = true
                        } label: {
                            Label("Sao chép", systemImage: "doc.on.doc")
                        }
                    }
                } else {
                    Button {
                        isSelecting = true
                    } label: {
                        Label("Chọn nhiều", systemImage: "checkmark.circle")
                    }
                    Spacer()
                    // Nút chuyển chế độ phát âm liên tục
                    Button(action: {
                        isContinuousMode.toggle()
                        if !isContinuousMode {
                            loopingWordId = nil
                            speechHelper.stopSpeaking()
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: isContinuousMode ? "repeat.circle.fill" : "repeat.circle")
                            Text("Phát liên tục")
                                .font(.subheadline)
                        }
                        .foregroundColor(isContinuousMode ? .blue : .gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))

            // Danh sách từ vựng
            List {
                ForEach(topic.items, id: \.id) { item in
                    HStack(alignment: .center, spacing: 12) {
                        // Hình minh hoạ
                        if let data = item.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .center) {
                                Text(item.word)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                if !item.phonetic.isEmpty {
                                    Text("[\(item.phonetic)]")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(.green)
                                Text(item.meaningVi)
                                    .foregroundColor(.green)
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                        // --- Nút phát âm ---
                        Button(action: {
                            if isContinuousMode {
                                if loopingWordId == item.id {
                                    loopingWordId = nil
                                    speechHelper.stopSpeaking()
                                } else {
                                    loopingWordId = item.id
                                    speechHelper.loopSpeak(text: item.word, id: item.id) {
                                        isContinuousMode && loopingWordId == item.id
                                    }
                                }
                            } else {
                                speakingWordId = item.id
                                speechHelper.speakEnglish(text: item.word)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    if speakingWordId == item.id {
                                        speakingWordId = nil
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(
                                    (isContinuousMode && loopingWordId == item.id) ? .green
                                    : (speakingWordId == item.id ? .orange : .blue)
                                )
                                .scaleEffect(speakingWordId == item.id ? 1.3 : 1.0)
                                .animation(.easeOut(duration: 0.2), value: speakingWordId == item.id)
                        }
                        .buttonStyle(.plain)
                        if isSelecting {
                            Button(action: {
                                if selectedItems.contains(item.id) {
                                    selectedItems.remove(item.id)
                                } else {
                                    selectedItems.insert(item.id)
                                }
                            }) {
                                Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            if selectedItems.contains(item.id) {
                                selectedItems.remove(item.id)
                            } else {
                                selectedItems.insert(item.id)
                            }
                        } else {
                            selectedItem = item
                        }
                    }
                }
                .onDelete { indexes in
                    topic.items.remove(atOffsets: indexes)
                    saveTopicChanges()
                }
            }
            .listStyle(.plain)

            Spacer()

            // Nút chức năng Flash-card & Quiz
            HStack(spacing: 16) {
                NavigationLink(destination: FlashcardView(items: topic.items)) {
                    HStack(spacing: 6) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 18, weight: .regular))
                        Text("Flash-card")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.purple.opacity(0.13))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: QuizView(items: topic.items)) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .regular))
                        Text("Quiz")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.orange.opacity(0.13))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: -2)
            )
            .padding(.bottom, 20)
        }

        .sheet(isPresented: $showAddWord) {
            AddWordView(onAdd: { newItem in
                topic.items.append(newItem)
                saveTopicChanges()
            })
        }
        .sheet(item: $selectedItem) { item in
            VocabDetailView(
                isPresented: Binding(
                    get: { selectedItem != nil },
                    set: { newValue in if !newValue { selectedItem = nil } }
                ),
                item: item,
                onEdit: { editedItem in
                    if let idx = topic.items.firstIndex(where: { $0.id == editedItem.id }) {
                        topic.items[idx] = editedItem
                        saveTopicChanges()
                    }
                }
            )
        }
        .alert("Đổi tên chủ đề", isPresented: $showRenameAlert) {
            TextField("Tên mới", text: $newTopicName)
            Button("Lưu") {
                let trimmed = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && trimmed != topic.title {
                    topic.title = trimmed
                    saveTopicChanges()
                }
            }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Nhập tên chủ đề mới")
        }
        .sheet(isPresented: $showCopySheet) {
            SelectTopicSheet(
                topics: allTopics.filter { $0.id != topic.id },
                onSelect: { destTopic in
                    let itemsToCopy = topic.items.filter { selectedItems.contains($0.id) }
                    var newAllTopics = allTopics
                    if let destIdx = newAllTopics.firstIndex(where: { $0.id == destTopic.id }) {
                        let existingIDs = Set(newAllTopics[destIdx].items.map { $0.id })
                        let itemsReallyCopy = itemsToCopy.map { orig in
                            existingIDs.contains(orig.id) ? orig.copyWithNewID() : orig
                        }
                        newAllTopics[destIdx].items.append(contentsOf: itemsReallyCopy)
                        onUpdateAllTopics(newAllTopics)
                    }
                    selectedItems.removeAll()
                    isSelecting = false
                },
                onCancel: {}
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    func saveTopicChanges() {
        var topics = UserDefaults.standard.loadTopics()
        if let idx = topics.firstIndex(where: { $0.id == topic.id }) {
            topics[idx] = topic
            UserDefaults.standard.saveTopics(topics)
            onUpdate(topic)
            let widgetCards: [WidgetFlashcard] = topic.items.map { item in
                WidgetFlashcard(
                    id: item.id,
                    word: item.word,
                    meaning: item.meaningVi,
                    imageData: item.imageData
                )
            }
            saveFlashcardsToAppGroup(widgetCards)
        }
    }
}
