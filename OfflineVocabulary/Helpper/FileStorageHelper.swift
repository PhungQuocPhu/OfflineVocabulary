import Foundation

/// File-based storage helper for managing vocabulary data
/// Replaces UserDefaults-based storage with JSON files for better scalability
class FileStorageHelper {
    
    // MARK: - Storage Locations
    
    /// Main app storage file for vocabulary topics
    private static let topicsFileName = "vocab_topics.json"
    
    /// App Group identifier for sharing data with widget
    private static let appGroupIdentifier = "group.phungquocphu.moments"
    
    /// Widget flashcards file name in App Group container
    private static let widgetFlashcardsFileName = "widget_flashcards.json"
    
    /// Widget configuration file name in App Group container
    private static let widgetConfigFileName = "widget_config.json"
    
    // MARK: - File Paths
    
    /// Returns the file URL for topics in the app's Documents directory
    static func topicsFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(topicsFileName)
    }
    
    /// Returns the App Group's shared container directory URL
    static func appGroupContainerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    /// Returns the file URL for widget flashcards in App Group container
    static func widgetFlashcardsFileURL() -> URL? {
        guard let containerURL = appGroupContainerURL() else { return nil }
        return containerURL.appendingPathComponent(widgetFlashcardsFileName)
    }
    
    /// Returns the file URL for widget configuration in App Group container
    static func widgetConfigFileURL() -> URL? {
        guard let containerURL = appGroupContainerURL() else { return nil }
        return containerURL.appendingPathComponent(widgetConfigFileName)
    }
    
    // MARK: - Generic File Operations
    
    /// Save Codable data to a file
    static func save<T: Codable>(_ data: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: url, options: [.atomic])
        print("✅ Successfully saved data to: \(url.path)")
    }
    
    /// Load Codable data from a file
    static func load<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(type, from: data)
        print("✅ Successfully loaded data from: \(url.path)")
        return decodedData
    }
    
    /// Check if a file exists at the given URL
    static func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Topics Storage
    
    /// Save vocabulary topics to the Documents directory
    static func saveTopics(_ topics: [VocabTopic]) {
        do {
            let url = topicsFileURL()
            try save(topics, to: url)
        } catch {
            print("❌ Error saving topics: \(error.localizedDescription)")
        }
    }
    
    /// Load vocabulary topics from the Documents directory
    static func loadTopics() -> [VocabTopic] {
        let url = topicsFileURL()
        
        // If file doesn't exist, try to migrate from UserDefaults
        if !fileExists(at: url) {
            print("📦 Topics file not found, attempting migration from UserDefaults...")
            return migrateTopicsFromUserDefaults()
        }
        
        do {
            return try load([VocabTopic].self, from: url)
        } catch {
            print("❌ Error loading topics: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Widget Flashcards Storage
    
    /// Save widget flashcards to the App Group container
    static func saveWidgetFlashcards(_ cards: [WidgetFlashcard]) {
        guard let url = widgetFlashcardsFileURL() else {
            print("❌ Unable to access App Group container for widget flashcards")
            return
        }
        
        do {
            try save(cards, to: url)
        } catch {
            print("❌ Error saving widget flashcards: \(error.localizedDescription)")
        }
    }
    
    /// Load widget flashcards from the App Group container
    static func loadWidgetFlashcards() -> [WidgetFlashcard] {
        guard let url = widgetFlashcardsFileURL() else {
            print("❌ Unable to access App Group container for widget flashcards")
            return []
        }
        
        // If file doesn't exist, try to migrate from UserDefaults
        if !fileExists(at: url) {
            print("📦 Widget flashcards file not found, attempting migration from UserDefaults...")
            return migrateWidgetFlashcardsFromUserDefaults()
        }
        
        do {
            return try load([WidgetFlashcard].self, from: url)
        } catch {
            print("❌ Error loading widget flashcards: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Widget Configuration Storage
    
    /// Widget configuration model
    struct WidgetConfig: Codable {
        var selectedTopicIDs: [UUID]
        var changeIntervalSeconds: Int
        
        init(selectedTopicIDs: [UUID] = [], changeIntervalSeconds: Int = 300) {
            self.selectedTopicIDs = selectedTopicIDs
            self.changeIntervalSeconds = changeIntervalSeconds
        }
    }
    
    /// Save widget configuration to the App Group container
    static func saveWidgetConfig(_ config: WidgetConfig) {
        guard let url = widgetConfigFileURL() else {
            print("❌ Unable to access App Group container for widget config")
            return
        }
        
        do {
            try save(config, to: url)
        } catch {
            print("❌ Error saving widget config: \(error.localizedDescription)")
        }
    }
    
    /// Load widget configuration from the App Group container
    static func loadWidgetConfig() -> WidgetConfig {
        guard let url = widgetConfigFileURL() else {
            print("❌ Unable to access App Group container for widget config")
            return WidgetConfig()
        }
        
        // If file doesn't exist, try to migrate from UserDefaults
        if !fileExists(at: url) {
            print("📦 Widget config file not found, attempting migration from UserDefaults...")
            return migrateWidgetConfigFromUserDefaults()
        }
        
        do {
            return try load(WidgetConfig.self, from: url)
        } catch {
            print("❌ Error loading widget config: \(error.localizedDescription)")
            return WidgetConfig()
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    /// Migrate topics from UserDefaults to file storage
    /// This ensures backward compatibility with existing data
    private static func migrateTopicsFromUserDefaults() -> [VocabTopic] {
        let topicsKey = "vocab_topics"
        
        if let data = UserDefaults.standard.data(forKey: topicsKey),
           let topics = try? JSONDecoder().decode([VocabTopic].self, from: data) {
            print("✅ Successfully migrated \(topics.count) topics from UserDefaults")
            
            // Save to new file storage
            saveTopics(topics)
            
            // Optionally remove from UserDefaults after successful migration
            UserDefaults.standard.removeObject(forKey: topicsKey)
            UserDefaults.standard.synchronize()
            print("🗑️ Cleaned up old UserDefaults storage for topics")
            
            return topics
        }
        
        print("ℹ️ No topics found in UserDefaults to migrate")
        return []
    }
    
    /// Migrate widget flashcards from UserDefaults to file storage
    private static func migrateWidgetFlashcardsFromUserDefaults() -> [WidgetFlashcard] {
        let flashcardsKey = "widget_flashcards"
        
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return []
        }
        
        if let data = userDefaults.data(forKey: flashcardsKey),
           let cards = try? JSONDecoder().decode([WidgetFlashcard].self, from: data) {
            print("✅ Successfully migrated \(cards.count) widget flashcards from UserDefaults")
            
            // Save to new file storage
            saveWidgetFlashcards(cards)
            
            // Optionally remove from UserDefaults after successful migration
            userDefaults.removeObject(forKey: flashcardsKey)
            userDefaults.synchronize()
            print("🗑️ Cleaned up old UserDefaults storage for widget flashcards")
            
            return cards
        }
        
        print("ℹ️ No widget flashcards found in UserDefaults to migrate")
        return []
    }
    
    /// Migrate widget configuration from UserDefaults to file storage
    private static func migrateWidgetConfigFromUserDefaults() -> WidgetConfig {
        let selectedTopicIDsKey = "widget_selected_topic_ids"
        let changeIntervalKey = "widget_change_interval"
        
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return WidgetConfig()
        }
        
        let idStrings = userDefaults.stringArray(forKey: selectedTopicIDsKey) ?? []
        let selectedIDs = idStrings.compactMap { UUID(uuidString: $0) }
        let intervalSeconds = userDefaults.integer(forKey: changeIntervalKey)
        let interval = (intervalSeconds > 0) ? intervalSeconds : 300
        
        let config = WidgetConfig(selectedTopicIDs: selectedIDs, changeIntervalSeconds: interval)
        
        if !selectedIDs.isEmpty || intervalSeconds > 0 {
            print("✅ Successfully migrated widget config from UserDefaults")
            
            // Save to new file storage
            saveWidgetConfig(config)
            
            // Optionally remove from UserDefaults after successful migration
            userDefaults.removeObject(forKey: selectedTopicIDsKey)
            userDefaults.removeObject(forKey: changeIntervalKey)
            userDefaults.synchronize()
            print("🗑️ Cleaned up old UserDefaults storage for widget config")
        }
        
        return config
    }
}
