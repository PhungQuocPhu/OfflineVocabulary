import Foundation
import UIKit

// MARK: - Từ vựng
struct VocabItem: Identifiable, Codable, Hashable {
    var id: UUID
    var word: String
    var meaningVi: String
    var phonetic: String
    var example: String?
    var imageData: Data? // lưu UIImage dưới dạng Data
}

// MARK: - Chủ đề từ vựng
struct VocabTopic: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var items: [VocabItem]
}

// MARK: - Loại câu hỏi Quiz
enum QuizType: String, Codable, CaseIterable {
    case chooseMeaning   // chọn nghĩa đúng cho từ tiếng Anh
    case chooseWord      // chọn từ đúng cho nghĩa tiếng Việt
    case fillBlank       // điền khuyết (blank)
    case listenAndWrite  // nghe và viết lại từ/cụm từ (mới)
}

// MARK: - Câu hỏi quiz
struct QuizQuestion: Identifiable, Codable, Hashable {
    let id: UUID
    let type: QuizType
    let question: String
    let options: [String]         // đáp án lựa chọn, nếu có
    let correctIndex: Int         // index của đáp án đúng trong mảng options
    let correctAnswer: String     // đáp án đúng (dùng cho fillBlank, listenAndWrite)
    let word: VocabItem           // từ vựng liên quan tới câu hỏi

    init(type: QuizType, question: String, options: [String], correctIndex: Int, correctAnswer: String, word: VocabItem) {
        self.id = UUID()
        self.type = type
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.correctAnswer = correctAnswer
        self.word = word
    }
}

// MARK: - Kết quả từng câu trong Quiz
struct QuizResult: Identifiable, Codable, Hashable {
    let id: UUID
    let question: QuizQuestion
    let selected: Int?        // index đáp án người dùng chọn (nếu có)
    let isCorrect: Bool       // đúng/sai
    let userInput: String?    // đáp án người dùng nhập (cho fillBlank, listenAndWrite)

    init(question: QuizQuestion, selected: Int?, isCorrect: Bool, userInput: String?) {
        self.id = UUID()
        self.question = question
        self.selected = selected
        self.isCorrect = isCorrect
        self.userInput = userInput
    }
}
