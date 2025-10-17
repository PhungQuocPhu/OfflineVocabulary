import SwiftUI

struct CustomUnderscoreInputView: View {
    let answer: String
    @Binding var userInput: String
    @FocusState private var isFocused: Bool

    var body: some View {
        let answerArray = Array(answer)
        let inputArray = Array(userInput)
        HStack(spacing: 8) {
            ForEach(0..<answerArray.count, id: \.self) { i in
                let ch = answerArray[i]
                ZStack {
                    if ch.isLetter || ch.isNumber {
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 26, height: 4)
                            .foregroundColor(.black)
                            .opacity(0.75)
                            .offset(y: 12)
                        Text(i < inputArray.count ? String(inputArray[i]) : "")
                            .font(.title2)
                            .frame(width: 26, height: 32)
                    } else {
                        Text(String(ch))
                            .font(.title2)
                            .frame(width: 26, height: 32)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .background(
            TextField("", text: $userInput)
                .focused($isFocused)
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .frame(width: 0, height: 0)
                .opacity(0.01)
                .onChange(of: userInput) { newValue in
                    if newValue.count > answerArray.count {
                        userInput = String(newValue.prefix(answerArray.count))
                    }
                }
        )
    }
}
