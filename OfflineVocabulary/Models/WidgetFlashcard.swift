import Foundation

struct WidgetFlashcard: Codable, Identifiable {
    let id: UUID
    let word: String
    let meaning: String
    let imageData: Data? // Hình ảnh, nếu có
}
