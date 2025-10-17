import SwiftUI
import UniformTypeIdentifiers

struct ImportTopicPicker: UIViewControllerRepresentable {
    var onImport: (VocabTopic?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImport: onImport)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onImport: (VocabTopic?) -> Void
        init(onImport: @escaping (VocabTopic?) -> Void) {
            self.onImport = onImport
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first, let data = try? Data(contentsOf: url) else {
                onImport(nil)
                return
            }
            let decoder = JSONDecoder()
            if let topic = try? decoder.decode(VocabTopic.self, from: data) {
                onImport(topic)
            } else {
                onImport(nil)
            }
        }
    }
}
