import SwiftUI

struct QuizResultCardView: View {
    let r: QuizResult
    let index: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Question \(index + 1): \(r.question.question)")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
                answerSection
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(r.isCorrect ? Color.green.opacity(0.08) : Color.red.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(r.isCorrect ? Color.green.opacity(0.8) : Color.red.opacity(0.7), lineWidth: 2)
            )
            .shadow(color: (r.isCorrect ? Color.green : Color.red).opacity(0.08), radius: 3, x: 0, y: 2)

            Image(systemName: r.isCorrect ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.title)
                .foregroundColor(r.isCorrect ? .green : .red)
                .padding([.top, .trailing], 12)
        }
    }

    @ViewBuilder
    var answerSection: some View {
        if r.question.type == .fillBlank || r.question.type == .listenAndWrite {
            Text("Your answer: \(r.userInput ?? "-")")
                .foregroundColor(r.isCorrect ? .green : .red)
                .font(.body)
            Text("Correct answer: \(r.question.correctAnswer)")
                .foregroundColor(.green)
                .font(.body)
        } else {
            Text("Your choice: \(r.selected != nil ? r.question.options[r.selected!] : "-")")
                .foregroundColor(r.isCorrect ? .green : .red)
                .font(.body)
            Text("Correct answer: \(r.question.options[r.question.correctIndex])")
                .foregroundColor(.green)
                .font(.body)
        }
    }
}
