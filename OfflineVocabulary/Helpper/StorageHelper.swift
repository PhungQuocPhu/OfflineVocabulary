import Foundation

/// Extension to maintain API compatibility while using file-based storage
/// This allows existing code to continue working without major refactoring
extension UserDefaults {
    
    /// Save vocabulary topics using file-based storage
    /// Migration from UserDefaults to file storage happens automatically
    func saveTopics(_ topics: [VocabTopic]) {
        FileStorageHelper.saveTopics(topics)
    }

    /// Load vocabulary topics using file-based storage
    /// Automatically migrates data from UserDefaults on first run
    func loadTopics() -> [VocabTopic] {
        return FileStorageHelper.loadTopics()
    }
}
