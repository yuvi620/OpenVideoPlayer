import SwiftUI
import SwiftData

@main
public struct OpenVideoPlayerApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [BookmarkEntity.self, WatchHistoryEntity.self])
    }
}
