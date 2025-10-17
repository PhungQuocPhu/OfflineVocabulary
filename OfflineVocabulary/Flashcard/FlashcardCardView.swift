import SwiftUI

struct FlashcardCardView: View {
    let item: VocabItem
    let isMastered: Bool
    let onToggleMastered: (UUID) -> Void

    @State private var rotation: Double = 0

    private var isFlipped: Bool {
        rotation.truncatingRemainder(dividingBy: 360) >= 90 && rotation.truncatingRemainder(dividingBy: 360) < 270
    }

    var body: some View {
        ZStack {
            // Front
            Group {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.blue.opacity(0.22))
                    .shadow(radius: 9)
                    .overlay(cardFrontContent)
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            // Back
            Group {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.orange.opacity(0.25))
                    .shadow(radius: 9)
                    .overlay(cardBackContent)
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 340)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: rotation)
        .onTapGesture {
            withAnimation {
                rotation += 180
                if rotation >= 360 { rotation -= 360 }
            }
        }
        // Play audio automatically when the card appears or word changes
        .onAppear {
            SpeechHelper.shared.speakEnglish(text: item.word)
        }
        .onChange(of: item.word) { newValue in
            SpeechHelper.shared.speakEnglish(text: newValue)
        }
    }

    private var cardFrontContent: some View {
        VStack {
            Spacer()
            VStack(spacing: 18) {
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                Text(item.word)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                if !item.phonetic.isEmpty {
                    Text("[\(item.phonetic)]")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                Button(action: {
                    SpeechHelper.shared.speakEnglish(text: item.word)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 36)
        .padding(.vertical, 32)
    }

    private var cardBackContent: some View {
        VStack {
            Spacer()
            VStack(spacing: 18) {
                Text(item.meaningVi)
                    .font(.title)
                    .foregroundColor(.green)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                if let ex = item.example, !ex.isEmpty {
                    Text("Example: \(ex)")
                        .italic()
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
            Button(action: {
                onToggleMastered(item.id)
            }) {
                Label(
                    isMastered ? "Mastered!" : "Need Review",
                    systemImage: isMastered ? "checkmark.seal.fill" : "arrow.2.circlepath.circle.fill"
                )
                .font(.title3)
                .foregroundColor(isMastered ? .green : .orange)
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 32)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Fix text backward
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
