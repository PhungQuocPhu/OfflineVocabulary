import SwiftUI

struct QuizOptionButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.title3)
                    .foregroundColor(.primary)
                Spacer()
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}
