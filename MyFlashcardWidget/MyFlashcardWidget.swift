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

        // Đọc interval từ UserDefaults (App Group)
        let groupName = "group.phungquocphu.moments"
        let intervalKey = "widget_change_interval"
        let seconds = UserDefaults(suiteName: groupName)?.integer(forKey: intervalKey) ?? 300
        let nextUpdate = Calendar.current.date(byAdding: .second, value: max(60, seconds), to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadFlashcardsFromAppGroup() -> [WidgetFlashcard] {
        let groupName = "group.phungquocphu.moments"
        if let data = UserDefaults(suiteName: groupName)?.data(forKey: "widget_flashcards"),
           let cards = try? JSONDecoder().decode([WidgetFlashcard].self, from: data) {
            return cards
        }
        return []
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
