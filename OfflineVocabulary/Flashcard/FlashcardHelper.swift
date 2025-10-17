import Foundation

struct FlashcardHelper {
    static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    // Thêm các hàm xử lý text, logic dùng chung cho Flashcard nếu cần
}
