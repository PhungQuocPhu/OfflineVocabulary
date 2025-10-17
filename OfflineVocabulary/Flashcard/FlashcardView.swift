import SwiftUI

struct FlashcardView: View {
    @State var items: [VocabItem]
    @State private var currentIndex: Int = 0
    @State private var mastered: [UUID: Bool] = [:]
    @State private var randomMode: Bool = false   // random mode: chuyển card sẽ random
    @State private var filterAll: Bool = true
    @State private var showMastered: Bool = false

    // Auto play state
    @State private var isAutoPlay: Bool = false
    @State private var autoPlaySpeed: Double = 2.0 // seconds per card (default)
    @State private var autoPlayTimer: Timer? = nil

    var filteredItems: [VocabItem] {
        if filterAll {
            return items
        } else {
            return items.filter { mastered[$0.id] == showMastered }
        }
    }
    var displayedIndex: Int? {
        guard !filteredItems.isEmpty else { return nil }
        let id = currentItem?.id
        return filteredItems.firstIndex(where: { $0.id == id })
    }
    var currentItem: VocabItem? {
        guard !filteredItems.isEmpty, currentIndex < filteredItems.count else { return nil }
        return filteredItems[currentIndex]
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 14) {
                // Filter row + random + auto play
                HStack(spacing: 10) {
                    Button(action: {
                        filterAll = true
                        currentIndex = 0
                    }) {
                        Text("All")
                            .frame(minWidth: 38)
                            .padding(.vertical, 7)
                            .background(filterAll ? Color.blue.opacity(0.75) : Color.clear)
                            .foregroundColor(filterAll ? .white : .blue)
                            .font(.system(size: 16, weight: .bold))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        filterAll = false
                        showMastered.toggle()
                        currentIndex = 0
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showMastered ? "checkmark.seal.fill" : "arrow.2.circlepath.circle.fill")
                                .foregroundColor(showMastered ? .green : .orange)
                            Text("Mas")
                                .foregroundColor(showMastered ? .green : .orange)
                        }
                        .frame(minWidth: 54)
                        .padding(.vertical, 7)
                        .background(!filterAll ? (showMastered ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)) : Color.clear)
                        .font(.system(size: 16, weight: .bold))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    // Random mode button
                    Button(action: {
                        randomMode.toggle()
                    }) {
                        Image(systemName: randomMode ? "shuffle.circle.fill" : "shuffle.circle")
                            .font(.system(size: 32))
                            .foregroundColor(randomMode ? .green : .gray)
                            .padding(.trailing, 2)
                    }
                    .accessibilityLabel("Random Mode")

                    // Auto play button
                    Button(action: {
                        toggleAutoPlay()
                    }) {
                        Image(systemName: isAutoPlay ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isAutoPlay ? .green : .gray)
                    }
                    .accessibilityLabel(isAutoPlay ? "Pause Auto Play" : "Auto Play")
                }
                .padding(.horizontal)

                // Auto play speed slider (only show when isAutoPlay is true)
                if isAutoPlay {
                    HStack(spacing: 14) {
                        Image(systemName: "hare.fill")
                            .foregroundColor(.gray)
                        Slider(value: $autoPlaySpeed, in: 1...5, step: 0.5) { _ in
                            restartAutoPlayTimer()
                        }
                        .frame(width: 140)
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(.gray)
                        Text("\(String(format: "%.1f", autoPlaySpeed))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 10)
                if let item = currentItem {
                    FlashcardCardView(
                        item: item,
                        isMastered: mastered[item.id] ?? false,
                        onToggleMastered: { id in
                            mastered[id] = !(mastered[id] ?? false)
                        }
                    )
                    if let idx = displayedIndex {
                        Text("Card \(idx+1)/\(filteredItems.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.blue.opacity(0.12))
                        .overlay(Text("No words").font(.title2))
                        .frame(height: 340)
                }
                Spacer()
                // Navigation (chỉ còn 2 nút trái/phải)
                HStack(spacing: 48) {
                    Button(action: { moveCard(prev: true) }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                    Button(action: { moveCard(prev: false) }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
            }
            .navigationTitle("Flashcards")
            .padding()
        }
        .onChange(of: filterAll) { _ in currentIndex = 0 }
        .onChange(of: showMastered) { _ in currentIndex = 0 }
        .onAppear {
            if isAutoPlay { startAutoPlay() }
        }
        .onDisappear {
            stopAutoPlay()
        }
    }

    // MARK: - Auto Play logic
    private func toggleAutoPlay() {
        isAutoPlay.toggle()
        if isAutoPlay {
            startAutoPlay()
        } else {
            stopAutoPlay()
        }
    }

    private func startAutoPlay() {
        stopAutoPlay()
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: autoPlaySpeed, repeats: true) { _ in
            moveCard(prev: false)
        }
    }
    private func restartAutoPlayTimer() {
        if isAutoPlay {
            startAutoPlay()
        }
    }
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }

    private func moveCard(prev: Bool) {
        let n = filteredItems.count
        guard n > 0 else { return }
        if randomMode {
            var newIndex: Int
            repeat { newIndex = Int.random(in: 0..<n) } while n > 1 && newIndex == currentIndex
            currentIndex = newIndex
        } else {
            let next = (currentIndex + (prev ? -1 : 1) + n) % n
            currentIndex = next
        }
    }
}
