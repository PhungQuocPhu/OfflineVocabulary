import SwiftUI
import UniformTypeIdentifiers

struct ImportTopicView: View {
    var onImport: ([VocabTopic]) -> Void
    @State private var showFileImporter = false
    @State private var errorMsg = ""

    var body: some View {
        VStack {
            Button("Chọn file JSON") {
                showFileImporter = true
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        let data = try Data(contentsOf: url)
                        let imported = try JSONDecoder().decode([VocabTopic].self, from: data)
                        onImport(imported)
                        // --- THÊM ĐOẠN SAU ĐỂ ĐỒNG BỘ SANG WIDGET ---
                        // Gộp toàn bộ từ vựng của tất cả topic import
                        let allItems = imported.flatMap { $0.items }
                        let widgetCards = allItems.map { item in
                            WidgetFlashcard(
                                id: item.id,
                                word: item.word,
                                meaning: item.meaningVi,
                                imageData: item.imageData
                            )
                        }
                        saveFlashcardsToAppGroup(widgetCards)
                        // ------------------------------------------------
                    } catch {
                        errorMsg = "File không đúng định dạng hoặc lỗi."
                    }
                case .failure:
                    errorMsg = "Không chọn được file."
                }
            }
            if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.red) }
        }
        .padding()
    }
}
