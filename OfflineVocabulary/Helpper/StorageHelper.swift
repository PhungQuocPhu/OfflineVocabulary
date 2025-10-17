import Foundation

extension UserDefaults {
    private static let topicsKey = "vocab_topics"

    func saveTopics(_ topics: [VocabTopic]) {
        if let data = try? JSONEncoder().encode(topics) {
            set(data, forKey: UserDefaults.topicsKey)
        }
    }

    func loadTopics() -> [VocabTopic] {
        if let data = data(forKey: UserDefaults.topicsKey),
           let topics = try? JSONDecoder().decode([VocabTopic].self, from: data) {
            return topics
        }
        return []
    }
}
