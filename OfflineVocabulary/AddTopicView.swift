import SwiftUI

struct AddTopicView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var isSaving = false
    @State private var showDetail = false
    @State private var newTopic: VocabTopic? = nil

    var onSave: (VocabTopic) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Tên chủ đề", text: $title)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                Spacer()

                Button("Lưu chủ đề") {
                    isSaving = true
                    let topic = VocabTopic(id: UUID(), title: title, items: [])
                    newTopic = topic
                    onSave(topic)
                    // Sau khi lưu sẽ chuyển sang màn hình chi tiết chủ đề (VocabListView)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showDetail = true
                        isSaving = false
                        dismiss()
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .foregroundColor((title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving) ? .gray : .blue)
                .padding(.bottom, 30)
            }
            .padding()
            .navigationTitle("Thêm chủ đề")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                NavigationLink(
                    destination: newTopic.map {topic in
                        VocabListView(
                            topic: topic,
                            allTopics: [],
                            onUpdate: { _ in },
                            onUpdateAllTopics: { _ in }
                        )
                    },
                    isActive: $showDetail,
                    label: { EmptyView() }
                )
                .hidden()
            )
        }
    }
}
