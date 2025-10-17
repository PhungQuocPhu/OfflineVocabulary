import SwiftUI

struct TopicsView: View {
    @State var topics: [VocabTopic] = UserDefaults.standard.loadTopics()
    @State private var showAddTopic = false

    var body: some View {
        NavigationView {
            VStack {
                List(topics) { topic in
                    Text(topic.title)
                }
            }
            .onDisappear {
                UserDefaults.standard.saveTopics(topics)
            }
        }
        // Đoạn kiểm tra lưu JSON
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("OfflineVocabularyData/vocab_topics.json")
        if FileManager.default.fileExists(atPath: filePath.path) {
            print("✅ File JSON đã được lưu tại: \(filePath.path)")
        } else {
            print("❌ File JSON chưa được tạo.")
        }
    }
}