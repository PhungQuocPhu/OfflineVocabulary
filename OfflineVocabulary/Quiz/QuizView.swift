import SwiftUI

struct QuizView: View {
    let items: [VocabItem]
    @State private var questions: [QuizQuestion] = []
    @State private var currentQuestion: Int = 0
    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false
    @State private var correctCount: Int = 0
    @State private var results: [QuizResult] = []
    @State private var userInput: String = ""
    @State private var quizDone: Bool = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 22) {
                Text("Quiz")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 12)

                if quizDone {
                    ScrollView {
                        VStack(spacing: 16) {
                            let correct = results.filter { $0.isCorrect }.count
                            Text("Quiz Results")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Correct \(correct) / \(questions.count)")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Divider()
                            ForEach(results.indices, id: \.self) { i in
                                QuizResultCardView(r: results[i], index: i)
                            }
                            Divider()
                            if results.contains(where: { !$0.isCorrect }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Review incorrect words:")
                                        .bold()
                                        .foregroundColor(.orange)
                                    ForEach(results.filter{!$0.isCorrect}, id: \.question.word.id) { r in
                                        Text(r.question.word.word)
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                            Button("Retake Quiz") {
                                resetQuiz()
                            }
                            .padding(.top, 12)
                        }
                        .padding(.horizontal)
                    }
                } else if !questions.isEmpty && currentQuestion < questions.count {
                    let q = questions[currentQuestion]
                    Text(q.question)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)

                    if q.type == .fillBlank {
                        fillBlankView(q: q)
                    } else if q.type == .listenAndWrite {
                        listenAndWriteView(q: q)
                    } else {
                        multipleChoiceView(q: q)
                    }
                    Text("Question \(currentQuestion + 1)/\(questions.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                } else {
                    ProgressView("Generating Quiz...")
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            questions = QuizManager.generateQuestions(from: items)
        }
    }

    // MARK: - UI Components for each question type

    @ViewBuilder
    func fillBlankView(q: QuizQuestion) -> some View {
        TextField("Enter your answer...", text: $userInput)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.title2)
            .padding(.bottom, 10)
        Button("Submit") {
            let correct = QuizHelper.isCorrectAnswer(userInput: userInput, answer: q.correctAnswer)
            results.append(QuizResult(question: q, selected: nil, isCorrect: correct, userInput: userInput))
            if correct { correctCount += 1 }
            showResult = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                nextQuestion()
            }
        }
        .disabled(userInput.isEmpty)
        .padding(.bottom, 6)
        if showResult {
            Text(QuizHelper.isCorrectAnswer(userInput: userInput, answer: q.correctAnswer) ? "Correct!" : "Incorrect!")
                .font(.title3)
                .foregroundColor(QuizHelper.isCorrectAnswer(userInput: userInput, answer: q.correctAnswer) ? .green : .red)
        }
    }

    @ViewBuilder
    func listenAndWriteView(q: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            if let data = q.word.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 4)
            }
            Button(action: {
                SpeechHelper.shared.speakEnglish(text: q.correctAnswer)
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Play again")
                }
            }
            .padding(.bottom, 10)
            .onAppear {
                SpeechHelper.shared.speakEnglish(text: q.correctAnswer)
            }
            CustomUnderscoreInputView(
                answer: q.correctAnswer,
                userInput: $userInput
            )
            .padding(.bottom, 10)

            Button("Submit") {
                let correct = QuizHelper.isCorrectAnswer(userInput: userInput, answer: q.correctAnswer)
                results.append(QuizResult(question: q, selected: nil, isCorrect: correct, userInput: userInput))
                if correct { correctCount += 1 }
                showResult = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    nextQuestion()
                }
            }
            .disabled(userInput.isEmpty)
            .padding(.bottom, 6)

            if showResult {
                Text(QuizHelper.isCorrectAnswer(userInput: userInput, answer: q.correctAnswer) ? "Correct!" : "Incorrect!")
                    .font(.title3)
                    .foregroundColor(QuizHelper.isCorrectAnswer(userInput: userInput, answer: q.correctAnswer) ? .green : .red)
            }
        }
    }

    @ViewBuilder
    func multipleChoiceView(q: QuizQuestion) -> some View {
        ForEach(q.options.indices, id: \.self) { idx in
            QuizOptionButton(
                option: q.options[idx],
                isSelected: idx == selectedIndex,
                isCorrect: showResult && idx == q.correctIndex,
                isWrong: showResult && idx == selectedIndex && idx != q.correctIndex
            ) {
                selectedIndex = idx
                let correct = idx == q.correctIndex
                results.append(QuizResult(question: q, selected: idx, isCorrect: correct, userInput: nil))
                if correct { correctCount += 1 }
                showResult = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    nextQuestion()
                }
            }
            .disabled(showResult)
        }
    }

    // MARK: - Logic
    func nextQuestion() {
        selectedIndex = nil
        showResult = false
        userInput = ""
        currentQuestion += 1
        if currentQuestion >= questions.count {
            quizDone = true
        }
    }

    func resetQuiz() {
        currentQuestion = 0
        correctCount = 0
        selectedIndex = nil
        showResult = false
        userInput = ""
        quizDone = false
        results = []
        questions = QuizManager.generateQuestions(from: items)
    }
}
