import SwiftUI

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    public let onSelectVideo: (VideoItem) -> Void

    public init(onSelectVideo: @escaping (VideoItem) -> Void) {
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingIndicatorView("Fetching trending videos...")
                case .loaded(let items):
                    if items.isEmpty {
                        EmptyStateView(
                            title: "No Videos",
                            systemImage: "video.slash",
                            description: "No trending videos available for the selected region."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(items) { video in
                                    VideoCardView(video: video) {
                                        onSelectVideo(video)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                case .error(let msg):
                    ErrorStateView(message: msg) {
                        Task { await viewModel.loadTrendingVideos() }
                    }
                }
            }
            .navigationTitle("Trending")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("United States (US)") { viewModel.selectedRegionCode = "US"; Task { await viewModel.loadTrendingVideos() } }
                        Button("United Kingdom (GB)") { viewModel.selectedRegionCode = "GB"; Task { await viewModel.loadTrendingVideos() } }
                        Button("Canada (CA)") { viewModel.selectedRegionCode = "CA"; Task { await viewModel.loadTrendingVideos() } }
                        Button("India (IN)") { viewModel.selectedRegionCode = "IN"; Task { await viewModel.loadTrendingVideos() } }
                    } label: {
                        Label("Region", systemImage: "globe")
                    }
                }
            }
            .task {
                if case .idle = viewModel.state {
                    await viewModel.loadTrendingVideos()
                }
            }
            .refreshable {
                await viewModel.loadTrendingVideos()
            }
        }
    }
}
