import SwiftUI
import UniformTypeIdentifiers

struct TopicImportExportView: View {
    @Binding var topics: [VocabTopic]
    @State private var showImportPicker = false
    @State private var showShareSheet = false
    @State private var exportURL: URL? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 18) {
            Text("Import / Export Chủ đề từ vựng")
                .font(.title2)
                .bold()
                .padding(.top, 18)
            List {
                ForEach(topics, id: \.id) { topic in
                    HStack {
                        Text(topic.title)
                            .font(.headline)
                        Spacer()
                        Button {
                            exportTopicToFile(topic)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .listStyle(.plain)

            Button {
                showImportPicker = true
            } label: {
                Label("Import Topic", systemImage: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .padding(.top, 8)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                // GIẢI PHÁP CHUẨN: Mở quyền và copy file vào sandbox
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    do {
                        if FileManager.default.fileExists(atPath: tmpURL.path) {
                            try FileManager.default.removeItem(at: tmpURL)
                        }
                        try FileManager.default.copyItem(at: url, to: tmpURL)
                        importTopicFromFile(tmpURL)
                    } catch {
                        alertMessage = "Không thể import file: \(error.localizedDescription)"
                        showAlert = true
                    }
                } else {
                    alertMessage = "Không đủ quyền truy cập file! Vui lòng thử lại."
                    showAlert = true
                }
            case .failure(let error):
                alertMessage = "Import thất bại: \(error.localizedDescription)"
                showAlert = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL, FileManager.default.fileExists(atPath: url.path) {
                ShareSheet(activityItems: [url, "Exported from OfflineVocabulary!"])
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thông báo"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
    }

    func exportTopicToFile(_ topic: VocabTopic) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(topic) {
            let safeTitle = topic.title.replacingOccurrences(of: "[^A-Za-z0-9_\\-]", with: "_", options: .regularExpression)
            let fileName = "\(safeTitle)-\(topic.id.uuidString.prefix(8)).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try data.write(to: tempURL, options: .atomic)
                guard FileManager.default.fileExists(atPath: tempURL.path) else {
                    alertMessage = "Lỗi: File export không tồn tại."
                    showAlert = true
                    return
                }
                exportURL = tempURL
                DispatchQueue.main.async {
                    showShareSheet = true
                }
            } catch {
                alertMessage = "Lỗi khi lưu file export: \(error.localizedDescription)"
                showAlert = true
            }
        } else {
            alertMessage = "Không thể mã hóa chủ đề ra file JSON."
            showAlert = true
        }
    }

    func importTopicFromFile(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            if let topic = try? decoder.decode(VocabTopic.self, from: data) {
                appendTopic(topic)
            } else if let topicsArr = try? decoder.decode([VocabTopic].self, from: data) {
                for t in topicsArr { appendTopic(t) }
            } else {
                alertMessage = "Không thể đọc file. Định dạng không hợp lệ."
                showAlert = true
            }
        } catch {
            alertMessage = "Import thất bại: \(error.localizedDescription)"
            showAlert = true
        }
    }
    func appendTopic(_ importedTopic: VocabTopic) {
        var topicToAdd = importedTopic
        let isDuplicate = topics.contains(where: { $0.id == topicToAdd.id })
        if isDuplicate {
            topicToAdd.id = UUID()
            topicToAdd.title += " (imported)"
        }
        topics.append(topicToAdd)
        UserDefaults.standard.saveTopics(topics)
        alertMessage = "Import thành công chủ đề: \(topicToAdd.title)"
        showAlert = true

        // === ĐỒNG BỘ TỪ VỰNG THẬT SANG WIDGET NGAY SAU KHI IMPORT ===
        let allItems = topics.flatMap { $0.items }
        let widgetCards = allItems.map { item in
            WidgetFlashcard(
                id: item.id,
                word: item.word,
                meaning: item.meaningVi,
                imageData: item.imageData
            )
        }
        saveFlashcardsToAppGroup(widgetCards)
    }
}
