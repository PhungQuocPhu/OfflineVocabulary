import SwiftUI

struct EditWordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var item: VocabItem
    var onSave: (VocabItem) -> Void
    @State private var image: UIImage? = nil
    @State private var showImagePicker = false

    // Theo dõi clipboard có ảnh không để enable/disable nút Paste Image
    @State private var clipboardHasImage: Bool = UIPasteboard.general.image != nil

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "character.book.closed.fill")
                            .foregroundColor(.blue)
                        TextField("Word", text: $item.word)
                            .autocapitalization(.none)
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundColor(.purple)
                        TextField("Phonetic", text: $item.phonetic)
                            .autocapitalization(.none)
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.green)
                        TextField("Meaning", text: $item.meaningVi)
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "quote.bubble")
                            .foregroundColor(.orange)
                        TextField("Example", text: Binding(
                            get: { item.example ?? "" },
                            set: { item.example = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }
                Section(header: Text("ILLUSTRATION").font(.caption).foregroundColor(.gray)) {
                    HStack(spacing: 24) {
                        // Ảnh minh hoạ hoặc placeholder
                        Group {
                            if let imgData = item.imageData, let img = UIImage(data: imgData) {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
                            } else if let img = image {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 28))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }

                        Spacer()

                        // Nút chọn ảnh (gallery)
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 26))
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("Chọn ảnh từ thư viện")

                        // Nút paste ảnh clipboard
                        Button(action: {
                            // Đảm bảo tắt ImagePicker trước khi dán ảnh!
                            showImagePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                if let pastedImage = UIPasteboard.general.image {
                                    image = pastedImage
                                    item.imageData = pastedImage.jpegData(compressionQuality: 0.85)
                                }
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(.blue)
                        .disabled(!clipboardHasImage)
                        .accessibilityLabel("Dán ảnh từ clipboard")
                        .onAppear {
                            clipboardHasImage = UIPasteboard.general.image != nil
                        }
                        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                            clipboardHasImage = UIPasteboard.general.image != nil
                        }

                        // Nút xoá ảnh
                        if item.imageData != nil || image != nil {
                            Button(action: {
                                showImagePicker = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    image = nil
                                    item.imageData = nil
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 24))
                            }
                            .foregroundColor(.red)
                            .accessibilityLabel("Xoá ảnh")
                        }
                    }
                    .padding(.vertical, 6)
                }
                Section {
                    Button(action: {
                        if let img = image {
                            item.imageData = img.jpegData(compressionQuality: 0.85)
                        }
                        onSave(item)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Save", systemImage: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    .disabled(item.word.isEmpty || item.meaningVi.isEmpty)
                }
            }
            .navigationTitle("Edit Word")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image)
            }
            .onChange(of: image) { newImg in
                if let img = newImg {
                    item.imageData = img.jpegData(compressionQuality: 0.85)
                }
            }
        }
    }
}
