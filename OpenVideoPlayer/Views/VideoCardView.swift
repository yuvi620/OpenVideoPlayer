import SwiftUI

public struct VideoCardView: View {
    public let video: VideoItem
    public let action: () -> Void

    public init(video: VideoItem, action: @escaping () -> Void) {
        self.video = video
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: video.thumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .aspectRatio(16/9, contentMode: .fill)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        case .failure:
                            ZStack {
                                Rectangle().fill(Color.secondary.opacity(0.2))
                                Image(systemName: "video.slash")
                                    .foregroundColor(.secondary)
                            }
                            .aspectRatio(16/9, contentMode: .fill)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let dur = video.durationSeconds, dur > 0 {
                        Text(formatDuration(dur))
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(6)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(video.channelTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let views = video.viewCount {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatViews(views))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    private func formatViews(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM views", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK views", Double(count) / 1_000)
        } else {
            return "\(count) views"
        }
    }
}
