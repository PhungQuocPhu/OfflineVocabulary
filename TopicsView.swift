// ... existing content of TopicsView.swift ...

let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("OfflineVocabularyData/vocab_topics.json")
if FileManager.default.fileExists(atPath: filePath.path) {
    print("✅ File JSON đã được lưu tại: \(filePath.path)")
} else {
    print("❌ File JSON chưa được tạo.")
}

// ... remaining content of TopicsView.swift ...