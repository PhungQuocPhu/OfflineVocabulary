import SwiftUI

struct TopicsView: View {
    @State var topics: [VocabTopic] = UserDefaults.standard.loadTopics()
    @State private var showAddTopic = false
    @State private var showImportExport = false
    @State private var showWidgetConfig = false
    @State private var showSpeakingPractice = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var topicToDelete: VocabTopic? = nil
    @State private var showDeleteConfirm: Bool = false

    // Thêm binding nhận deeplink từ App
    @Binding var deepLinkedVocabId: UUID?
    // State để trigger navigation tới VocabDetailView
    @State private var vocabDetailItem: VocabItem? = nil
    @State private var showVocabDetail: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    headerSection
                    topicCardsList
                    Spacer()
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showAddTopic) {
                    AddTopicView { newTopic in
                        topics.append(newTopic)
                        UserDefaults.standard.saveTopics(topics)
                        syncAllTopicsToWidget()
                    }
                }
                .sheet(isPresented: $showImportExport) {
                    TopicImportExportView(topics: $topics)
                }
                .sheet(isPresented: $showWidgetConfig) {
                    WidgetConfigView(
                        allTopics: topics,
                        syncWidget: { syncAllTopicsToWidget()}
                    )
                }
                .sheet(isPresented: $showSpeakingPractice) {
                    SpeakingPracticeView(allTopics: topics)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Thông báo"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .confirmationDialog(
                    "Xoá chủ đề?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Xoá", role: .destructive) {
                        if let topic = topicToDelete {
                            topics.removeAll { $0.id == topic.id }
                            UserDefaults.standard.saveTopics(topics)
                            syncAllTopicsToWidget()
                        }
                        topicToDelete = nil
                    }
                    Button("Huỷ", role: .cancel) {
                        topicToDelete = nil
                    }
                }

                // NavigationLink ẩn: Điều hướng tới VocabDetailView khi có deeplink
                NavigationLink(
                    isActive: $showVocabDetail,
                    destination: {
                        Group {
                            if let item = vocabDetailItem {
                                VocabDetailView(isPresented: .constant(true), item: item, onEdit: { _ in }, showCloseButton: false)
                            } else {
                                Text("Không tìm thấy từ vựng")
                            }
                        }
                    }
                ) {
                    EmptyView()
                }
            }
            .onChange(of: deepLinkedVocabId) { newId in
                // Khi deeplink thay đổi, tìm đúng VocabItem và trigger navigation
                if let id = newId,
                   let item = topics.flatMap({ $0.items }).first(where: { $0.id == id }) {
                    vocabDetailItem = item
                    showVocabDetail = true
                } else {
                    vocabDetailItem = nil
                    showVocabDetail = false
                }
            }
            .onChange(of: showVocabDetail) { isActive in
                // Reset deeplink id khi đóng detail
                if !isActive {
                    deepLinkedVocabId = nil
                    vocabDetailItem = nil
                }
            }
        }
    }

    var headerSection: some View {
        HStack(alignment: .center) {
            Image(systemName: "folder.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Chủ đề từ vựng")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
                .padding(.top, 28)
                .padding(.bottom, 28)
            Spacer()
            // Nút menu tổng hợp
            Menu {
                Button {
                    showAddTopic = true
                } label: {
                    Label("Thêm chủ đề", systemImage: "plus")
                }
                Button {
                    showImportExport = true
                } label: {
                    Label("Import/Export", systemImage: "arrow.up.arrow.down.square.fill")
                }
                Button {
                    showWidgetConfig = true
                } label: {
                    Label("Cấu hình Widget", systemImage: "gearshape")
                }
                Button{
                    showSpeakingPractice = true
                } label: {
                    Label("Luyện nói (Shadowing)", systemImage: "mic.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 18)
    }

    var topicCardsList: some View {
        List {
            ForEach(Array(topics.enumerated()), id: \.element.id) { (idx, topic) in
                ZStack(alignment: .leading) {
                    NavigationLink(
                        destination: VocabListView(
                            topic: topic,
                            allTopics: topics,
                            onUpdate: { updatedTopic in
                                if let i = topics.firstIndex(where: { $0.id == updatedTopic.id }) {
                                    topics[i] = updatedTopic
                                    UserDefaults.standard.saveTopics(topics)
                                    syncAllTopicsToWidget()
                                }
                            },
                            onUpdateAllTopics: { updatedTopics in
                                topics = updatedTopics
                                UserDefaults.standard.saveTopics(topics)
                                syncAllTopicsToWidget()
                            }
                        )
                    ) {
                        EmptyView()
                    }
                    .opacity(0)

                    TopicCardView(
                        topic: topic,
                        gradient: LinearGradient(
                            colors: topicGradientColors[idx % topicGradientColors.count],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        mainColor: topicGradientColors[idx % topicGradientColors.count][0]
                    )
                    .contentShape(Rectangle())
                }
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        topicToDelete = topic
                        showDeleteConfirm = true
                    } label: {
                        Label("Xoá", systemImage: "trash.fill")
                    }
                    .disabled(topic.items.count > 0)
                }
            }
            .onDelete { indexes in
                topics.remove(atOffsets: indexes)
                UserDefaults.standard.saveTopics(topics)
                syncAllTopicsToWidget()
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Đồng bộ dữ liệu các topic thật sang widget (chỉ các topic đã chọn)
    func syncAllTopicsToWidget() {
        let selectedIDs = loadSelectedTopicIDs()
        let filteredTopics: [VocabTopic]
        if selectedIDs.isEmpty {
            filteredTopics = topics
        } else {
            filteredTopics = topics.filter { selectedIDs.contains($0.id) }
        }
        let allItems = filteredTopics.flatMap { $0.items }
        let widgetCards = allItems.map { item in
            WidgetFlashcard(
                id: item.id,
                word: item.word,
                meaning: item.meaningVi,
                imageData: item.imageData
            )
        }
        saveFlashcardsToAppGroup(widgetCards)
    }

    func loadSelectedTopicIDs() -> [UUID] {
        let groupName = "group.phungquocphu.moments"
        let selectedTopicIDsKey = "widget_selected_topic_ids"
        let idStrings = UserDefaults(suiteName: groupName)?.stringArray(forKey: selectedTopicIDsKey) ?? []
        return idStrings.compactMap { UUID(uuidString: $0) }
    }
}

// Các giá trị gradient màu cho chủ đề (nên để trong file riêng nếu dùng lại)
let topicGradientColors: [[Color]] = [
    [Color.indigo, Color.mint],
    [Color.blue, Color.cyan],
    [Color.orange, Color.yellow],
    [Color.green, Color.teal],
    [Color.pink, Color.purple],
    [Color(red: 0.75, green: 0.58, blue: 0.89), Color.blue.opacity(0.7)],
]
