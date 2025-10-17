import Foundation

struct QuizHelper {
    static func makeUnderscoreDisplay(for answer: String, userInput: String) -> String {
        var display = ""
        let answerArray = Array(answer)
        let inputArray = Array(userInput)
        for i in 0..<answerArray.count {
            let ch = answerArray[i]
            if ch.isLetter || ch.isNumber {
                if i < inputArray.count {
                    display.append(inputArray[i])
                } else {
                    display.append("_")
                }
            } else {
                display.append(ch)
            }
        }
        return display
    }

    static func normalizeInput(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isCorrectAnswer(userInput: String, answer: String) -> Bool {
        normalizeInput(userInput) == normalizeInput(answer)
    }
}
