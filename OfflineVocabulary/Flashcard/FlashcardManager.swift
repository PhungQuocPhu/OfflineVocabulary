import Foundation

struct FlashcardManager {
    static func shuffledItems(_ items: [VocabItem]) -> [VocabItem] {
        items.shuffled()
    }

    // Có thể bổ sung logic filter mastered, random theo chủ đề, v.v.
}
