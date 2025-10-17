import SwiftUI

struct AddWordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var word = ""
    @State private var phonetic = ""
    @State private var meaning = ""
    @State private var example = ""
    @State private var image: UIImage? = nil
    @State private var showImagePicker = false
    var onAdd: (VocabItem) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "character.book.closed.fill")
                            .foregroundColor(.blue)
                        TextField("Word", text: $word)
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundColor(.purple)
                        TextField("Phonetic", text: $phonetic)
                            .autocapitalization(.none)
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.green)
                        TextField("Meaning", text: $meaning)
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "quote.bubble")
                            .foregroundColor(.orange)
                        TextField("Example", text: $example)
                    }
                }
                Section(header: Text("Illustration")) {
                    HStack {
                        if let img = image {
                            Image(uiImage: img)
                                .resizable()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        Button(action: { showImagePicker = true }) {
                            Label("Add Image", systemImage: "photo.on.rectangle.angled")
                        }
                        .foregroundColor(.blue)
                    }
                }
                Section {
                    Button(action: {
                        let item = VocabItem(
                            id: UUID(),
                            word: word,
                            meaningVi: meaning,
                            phonetic: phonetic,
                            example: example.isEmpty ? nil : example,
                            imageData: image?.jpegData(compressionQuality: 0.85)
                        )
                        onAdd(item)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Add Word", systemImage: "plus.circle.fill")
                            .font(.title3)
                    }
                    .disabled(word.isEmpty || meaning.isEmpty)
                }
            }
            .navigationTitle("Add Word")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image)
            }
        }
    }
}
