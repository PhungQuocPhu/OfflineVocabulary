import Foundation

struct QuizManager {
    static func generateQuestions(from items: [VocabItem]) -> [QuizQuestion] {
        var qs: [QuizQuestion] = []
        let pool = items.filter { !$0.word.isEmpty && !$0.meaningVi.isEmpty }
        let shuffled = pool.shuffled()
        for item in shuffled {
            // 1. Choose correct meaning (show English word, choose meaning)
            var options1 = [item.meaningVi]
            let others1 = pool.filter { $0.id != item.id }.shuffled().prefix(3)
            options1.append(contentsOf: others1.map { $0.meaningVi })
            options1.shuffle()
            let correct1 = options1.firstIndex(of: item.meaningVi) ?? 0
            qs.append(QuizQuestion(
                type: .chooseMeaning,
                question: "What is the meaning of \"\(item.word)\"?",
                options: Array(options1),
                correctIndex: correct1,
                correctAnswer: item.meaningVi,
                word: item
            ))
            // 2. Choose correct word (show meaning, choose English word)
            var options2 = [item.word]
            let others2 = pool.filter { $0.id != item.id }.shuffled().prefix(3)
            options2.append(contentsOf: others2.map { $0.word })
            options2.shuffle()
            let correct2 = options2.firstIndex(of: item.word) ?? 0
            qs.append(QuizQuestion(
                type: .chooseWord,
                question: "Which word matches the meaning \"\(item.meaningVi)\"?",
                options: Array(options2),
                correctIndex: correct2,
                correctAnswer: item.word,
                word: item
            ))
            // 3. Fill blank (if has example)
            if let ex = item.example, !ex.isEmpty {
                let blanked = ex.replacingOccurrences(of: item.word, with: "______")
                qs.append(QuizQuestion(
                    type: .fillBlank,
                    question: "Fill in the blank: \(blanked)",
                    options: [],
                    correctIndex: 0,
                    correctAnswer: item.word,
                    word: item
                ))
            }
            // 4. Listen and write
            qs.append(QuizQuestion(
                type: .listenAndWrite,
                question: "Listen and type the word/phrase you hear:",
                options: [],
                correctIndex: 0,
                correctAnswer: item.word,
                word: item
            ))
        }
        return qs.shuffled()
    }
}
