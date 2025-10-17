import Foundation

func saveFlashcardsToAppGroup(_ cards: [WidgetFlashcard]) {
    let groupName = "group.phungquocphu.moments"
    if let data = try? JSONEncoder().encode(cards) {
        UserDefaults(suiteName: groupName)?.set(data, forKey: "widget_flashcards")
        print("✅ Saved flashcards to App Group")
    } else {
        print("❌ Failed to encode flashcards")
    }
}
