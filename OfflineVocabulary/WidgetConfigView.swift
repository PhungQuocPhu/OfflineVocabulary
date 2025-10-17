import SwiftUI
import WidgetKit

struct WidgetConfigView: View {
    let allTopics: [VocabTopic]
    var syncWidget: (() -> Void)? = nil // closure gọi sync từ ngoài vào, nếu muốn

    @State private var selectedIDs: Set<UUID> = []
    @State private var changeInterval: Double = 5 // phút, mặc định 5 phút
    @State private var showSavedAlert = false

    let minMinutes: Double = 1
    let maxMinutes: Double = 60

    // App Group config
    let groupName = "group.phungquocphu.moments"
    let selectedTopicIDsKey = "widget_selected_topic_ids"
    let changeIntervalKey = "widget_change_interval"

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chủ đề hiển thị trên Widget")) {
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

                Section(header: Text("Thời gian đổi từ trên Widget")) {
                    HStack {
                        Slider(value: $changeInterval, in: minMinutes...maxMinutes, step: 1)
                        Text("\(Int(changeInterval)) phút")
                            .frame(width: 60, alignment: .leading)
                    }
                    Text("Widget sẽ tự động thay đổi từ mỗi \(Int(changeInterval)) phút.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Lưu cấu hình") {
                        saveSelectedTopicIDs(Array(selectedIDs))
                        saveWidgetChangeInterval(Int(changeInterval * 60))
                        syncWidgetData()
                        WidgetCenter.shared.reloadAllTimelines() // <- cập nhật widget ngay lập tức
                        showSavedAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .navigationTitle("Cấu hình Widget")
            .onAppear {
                selectedIDs = Set(loadSelectedTopicIDs())
                changeInterval = Double(loadWidgetChangeInterval()) / 60.0
            }
            .alert(isPresented: $showSavedAlert) {
                Alert(title: Text("Đã lưu cấu hình!"), message: nil, dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - App Group Lưu/Đọc chủ đề đã chọn
    func saveSelectedTopicIDs(_ ids: [UUID]) {
        let idStrings = ids.map { $0.uuidString }
        UserDefaults(suiteName: groupName)?.set(idStrings, forKey: selectedTopicIDsKey)
    }
    func loadSelectedTopicIDs() -> [UUID] {
        let idStrings = UserDefaults(suiteName: groupName)?.stringArray(forKey: selectedTopicIDsKey) ?? []
        return idStrings.compactMap { UUID(uuidString: $0) }
    }

    // MARK: - Lưu/Đọc thời gian đổi từ cho Widget
    func saveWidgetChangeInterval(_ seconds: Int) {
        UserDefaults(suiteName: groupName)?.set(seconds, forKey: changeIntervalKey)
    }
    func loadWidgetChangeInterval() -> Int {
        let seconds = UserDefaults(suiteName: groupName)?.integer(forKey: changeIntervalKey) ?? 0
        return (seconds > 0) ? seconds : 300 // mặc định 5 phút
    }

    // MARK: - Đồng bộ dữ liệu widget tự động
    func syncWidgetData() {
        if let sync = syncWidget {
            sync()
            return
        }
        let filteredTopics: [VocabTopic]
        if selectedIDs.isEmpty {
            filteredTopics = allTopics
        } else {
            filteredTopics = allTopics.filter { selectedIDs.contains($0.id) }
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

    // MARK: - Lưu flashcards cho widget vào App Group
    func saveFlashcardsToAppGroup(_ cards: [WidgetFlashcard]) {
        let groupName = "group.phungquocphu.moments"
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults(suiteName: groupName)?.set(data, forKey: "widget_flashcards")
        }
    }
}
