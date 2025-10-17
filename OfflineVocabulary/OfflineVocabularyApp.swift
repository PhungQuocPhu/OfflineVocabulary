import SwiftUI
import Foundation

@main
struct OfflineVocabularyApp: App {
    // Thêm biến để lưu id từ vựng nhận từ deeplink
    @State var deepLinkedVocabId: UUID? = nil

    var body: some Scene {
        WindowGroup {
            TopicsView(deepLinkedVocabId: $deepLinkedVocabId)
                .accentColor(.blue) // Chủ đạo màu xanh cho toàn app
                .background(Color(.systemGroupedBackground))
                .onOpenURL { url in
                    // Nhận deeplink từ widget: offlinevocabulary://vocab-detail?id=...
                    if url.scheme == "offlinevocabulary",
                       url.host == "vocab-detail",
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                       let uuid = UUID(uuidString: idString) {
                        deepLinkedVocabId = uuid
                    }
                }
        }
    }
}
