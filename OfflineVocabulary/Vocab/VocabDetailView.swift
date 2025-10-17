import SwiftUI
import AVFoundation

struct VocabDetailView: View {
    @Binding var isPresented: Bool
    @State var item: VocabItem
    var onEdit: (VocabItem) -> Void
    var showCloseButton: Bool = true

    @State private var showEdit = false

    var body: some View {
        VStack(spacing: 0) {
            // Edit button top right
            HStack {
                Spacer()
                Button(action: { showEdit = true }) {
                    Label("Edit", systemImage: "pencil.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 20) {
                    // Image
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 180)
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                    }
                    // Word: dòng riêng, to, đậm
                    Text(item.word)
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    // Phonetic: dòng riêng, nhỏ, màu phụ, kèm nút phát âm bên phải
                    HStack(alignment: .center) {
                        if !item.phonetic.isEmpty {
                            Text("[\(item.phonetic)]")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            SpeechHelper.shared.speakEnglish(text: item.word)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Meaning: dòng riêng
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.green)
                        Text(item.meaningVi)
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                    // Example (if any)
                    if let ex = item.example, !ex.isEmpty {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(.purple)
                            Text(ex)
                                .italic()
                                .foregroundColor(.purple)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            Spacer()
            // Ẩn nút Close nếu mở qua deeplink (showCloseButton = false)
            if showCloseButton {
                Button(action: {
                    isPresented = false
                }) {
                    Label("Close", systemImage: "xmark.circle.fill")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showEdit) {
            EditWordView(item: item) { editedItem in
                item = editedItem
                onEdit(editedItem)
                showEdit = false
            }
        }
    }
}
