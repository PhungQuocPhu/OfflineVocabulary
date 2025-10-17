import SwiftUI
import WidgetKit

struct MyFlashcardWidgetEntryView: View {
    var entry: MyFlashcardEntry

    var body: some View {
        GeometryReader { geo in
            Link(destination: URL(string: "offlinevocabulary://vocab-detail?id=\(entry.card.id.uuidString)")!) {
                ZStack {
                    // Hình nền full widget
                    if let data = entry.card.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        Color(.systemGray5)
                    }
                    
                    // Overlay chữ full chiều ngang, không bo góc, canh bottom
                    VStack(spacing: 12) {
                        Spacer()
                        // Từ vựng: full chiều ngang, font lớn, nền mờ
                        Text(entry.card.word)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.5))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        // Nghĩa: full chiều ngang, font lớn, nền mờ
                        Text(entry.card.meaning)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.38))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: geo.size.width)
                    .padding(.bottom, geo.size.height * 0.05)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .containerBackground(.fill, for: .widget)
            }
        }
    }
}
