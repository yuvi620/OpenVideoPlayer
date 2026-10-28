import SwiftUI

public struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    public let onSelectVideo: (VideoItem) -> Void

    public init(onSelectVideo: @escaping (VideoItem) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    EmptyStateView(
                        title: "Discover Videos",
                        systemImage: "magnifyingglass",
                        description: "Search for videos, creators, or topics using the official YouTube Data API."
                    )
                case .loading:
                    LoadingIndicatorView("Searching videos...")
                case .loaded(let items, let hasMore):
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(items) { video in
                                VideoCardView(video: video) {
                                    onSelectVideo(video)
                                }
                            }
                            if hasMore {
                                ProgressView()
                                    .padding(.vertical, 12)
                                    .task {
                                        await viewModel.loadNextPage()
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                case .empty(let query):
                    EmptyStateView(
                        title: "No Results",
                        systemImage: "magnifyingglass",
                        description: "No videos found matching '\(query)'."
                    )
                case .error(let msg):
                    ErrorStateView(message: msg) {
                        viewModel.executeSearch(query: viewModel.queryText)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.queryText, prompt: "Search YouTube")
        }
    }
}
