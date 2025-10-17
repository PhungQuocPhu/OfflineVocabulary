import SwiftUI

struct SelectTopicSheet: View {
    var topics: [VocabTopic]
    var onSelect: (VocabTopic) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(topics) { topic in
                Button(action: {
                    onSelect(topic)
                    dismiss()
                }) {
                    Text(topic.title)
                        .font(.headline)
                }
            }
            .navigationTitle("Chọn chủ đề để sao chép")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
    }
}
