import SwiftUI
import SwiftData

public struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    public let onSelectVideo: (VideoItem) -> Void

    @Query(sort: \BookmarkEntity.dateAdded, order: .reverse) private var bookmarks: [BookmarkEntity]
    @Query(sort: \WatchHistoryEntity.lastWatchedDate, order: .reverse) private var watchHistory: [WatchHistoryEntity]
    @Environment(\.modelContext) private var modelContext

    public init(onSelectVideo: @escaping (VideoItem) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Library", selection: $viewModel.selectedSegment) {
                    ForEach(LibraryViewModel.LibrarySegment.allCases) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(12)

                Group {
                    if viewModel.selectedSegment == .bookmarks {
                        if bookmarks.isEmpty {
                            EmptyStateView(
                                title: "No Bookmarks Yet",
                                systemImage: "bookmark",
                                description: "Saved videos will appear here. Tap the bookmark icon while watching."
                            )
                        } else {
                            List {
                                ForEach(bookmarks) { item in
                                    Button(action: { onSelectVideo(item.toVideoItem()) }) {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: item.thumbnailURLString)) { img in
                                                img.resizable().aspectRatio(16/9, contentMode: .fill)
                                            } placeholder: {
                                                Rectangle().fill(Color.secondary.opacity(0.2))
                                            }
                                            .frame(width: 100, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.title)
                                                    .font(.subheadline.bold())
                                                    .lineLimit(2)
                                                Text(item.channelTitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .onDelete(perform: deleteBookmarks)
                            }
                            .listStyle(.plain)
                        }
                    } else {
                        if watchHistory.isEmpty {
                            EmptyStateView(
                                title: "Watch History is Empty",
                                systemImage: "clock",
                                description: "Videos you watch in OpenVideoPlayer will appear here with your resume position."
                            )
                        } else {
                            List {
                                ForEach(watchHistory) { hist in
                                    Button(action: { onSelectVideo(hist.toVideoItem()) }) {
                                        HStack(spacing: 12) {
                                            ZStack(alignment: .bottom) {
                                                AsyncImage(url: URL(string: hist.thumbnailURLString)) { img in
                                                    img.resizable().aspectRatio(16/9, contentMode: .fill)
                                                } placeholder: {
                                                    Rectangle().fill(Color.secondary.opacity(0.2))
                                                }
                                                .frame(width: 100, height: 56)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))

                                                GeometryReader { geo in
                                                    Rectangle()
                                                        .fill(Color.red)
                                                        .frame(width: geo.size.width * CGFloat(hist.progressFraction), height: 3)
                                                }
                                                .frame(height: 3)
                                            }
                                            .frame(width: 100, height: 56)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(hist.title)
                                                    .font(.subheadline.bold())
                                                    .lineLimit(2)
                                                Text(hist.channelTitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .onDelete(perform: deleteHistory)
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                if viewModel.selectedSegment == .history && !watchHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            for h in watchHistory { modelContext.delete(h) }
                        }
                    }
                }
            }
        }
    }

    private func deleteBookmarks(offsets: IndexSet) {
        for idx in offsets { modelContext.delete(bookmarks[idx]) }
    }

    private func deleteHistory(offsets: IndexSet) {
        for idx in offsets { modelContext.delete(watchHistory[idx]) }
    }
}
