import Foundation

/// Save flashcards to App Group shared container using file-based storage
/// This function is used to synchronize vocabulary data with the widget
/// Migration from UserDefaults to file storage happens automatically
func saveFlashcardsToAppGroup(_ cards: [WidgetFlashcard]) {
    FileStorageHelper.saveWidgetFlashcards(cards)
    print("✅ Saved \(cards.count) flashcards to App Group file storage")
}
