import WidgetKit
import SwiftUI

struct MyFlashcardEntry: TimelineEntry {
    let date: Date
    let card: WidgetFlashcard
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MyFlashcardEntry {
        MyFlashcardEntry(date: Date(), card: WidgetFlashcard(id: UUID(), word: "Từ mẫu", meaning: "Nghĩa mẫu", imageData: nil))
    }

    func getSnapshot(in context: Context, completion: @escaping (MyFlashcardEntry) -> Void) {
        completion(randomEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MyFlashcardEntry>) -> Void) {
        let entry = randomEntry()

        // Read interval from file-based storage (App Group)
        let config = FileStorageHelper.loadWidgetConfig()
        let seconds = config.changeIntervalSeconds
        let nextUpdate = Calendar.current.date(byAdding: .second, value: max(60, seconds), to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadFlashcardsFromAppGroup() -> [WidgetFlashcard] {
        return FileStorageHelper.loadWidgetFlashcards()
    }

    func randomEntry() -> MyFlashcardEntry {
        let cards = loadFlashcardsFromAppGroup()
        if let card = cards.randomElement() {
            return MyFlashcardEntry(date: Date(), card: card)
        }
        return MyFlashcardEntry(date: Date(), card: WidgetFlashcard(id: UUID(), word: "Chưa có từ", meaning: "Hãy mở app để cập nhật", imageData: nil))
    }
}
struct MyFlashcardWidget: Widget {
    let kind: String = "MyFlashcardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MyFlashcardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Flashcard Widget")
        .description("Hiển thị từ vựng ngẫu nhiên.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
