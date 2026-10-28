import SwiftUI

public struct MainTabView: View {
    @StateObject private var coordinator = HybridPlaybackCoordinator()
    @State private var activeVideo: VideoItem?

    public init() {}

    public var body: some View {
        TabView {
            HomeView { selected in
                activeVideo = selected
            }
            .tabItem {
                Label("Trending", systemImage: "flame")
            }

            SearchView { selected in
                activeVideo = selected
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            LibraryView { selected in
                activeVideo = selected
            }
            .tabItem {
                Label("Library", systemImage: "folder")
            }
        }
        .sheet(item: $activeVideo, onDismiss: {
            coordinator.stop()
        }) { video in
            VideoDetailView(video: video, coordinator: coordinator)
        }
    }
}
