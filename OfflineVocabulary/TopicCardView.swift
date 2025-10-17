import SwiftUI

struct TopicCardView: View {
    var topic: VocabTopic
    var gradient: LinearGradient
    var mainColor: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(gradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: mainColor.opacity(0.15), radius: 6, x: 0, y: 3)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(topic.title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.primary)
                Text("\(topic.items.count) từ vựng")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: mainColor.opacity(0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, 1)
        .padding(.vertical, 1)
    }
}
