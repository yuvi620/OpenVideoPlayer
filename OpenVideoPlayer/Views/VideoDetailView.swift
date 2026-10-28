import SwiftUI
import SwiftData

public struct VideoDetailView: View {
    public let video: VideoItem
    @ObservedObject public var coordinator: HybridPlaybackCoordinator
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: VideoDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(video: VideoItem, coordinator: HybridPlaybackCoordinator) {
        self.video = video
        self.coordinator = coordinator
        self._viewModel = StateObject(wrappedValue: VideoDetailViewModel(video: video))
    }

    public var body: some View {
        VStack(spacing: 0) {
            PlayerView(video: video, coordinator: coordinator)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(video.title)
                        .font(.title3.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(video.channelTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if let views = video.viewCount {
                            Text("\(views) views")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    HStack(spacing: 24) {
                        Button(action: { viewModel.toggleBookmark(modelContext: modelContext) }) {
                            VStack(spacing: 4) {
                                Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundColor(viewModel.isBookmarked ? .accentColor : .primary)
                                Text(viewModel.isBookmarked ? "Saved" : "Bookmark")
                                    .font(.caption2)
                            }
                        }

                        if let thumb = video.thumbnailURL {
                            ShareLink(item: thumb, subject: Text(video.title), message: Text("Watch \(video.title)")) {
                                VStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title3)
                                    Text("Share")
                                        .font(.caption2)
                                }
                            }
                        }
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)

                    Divider()

                    if !video.videoDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.headline)
                            Text(video.videoDescription)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            coordinator.load(item: video)
            viewModel.checkBookmarkStatus(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.recordWatchHistory(
                modelContext: modelContext,
                position: coordinator.currentTime,
                duration: coordinator.duration
            )
        }
    }
}
