import Foundation
import SwiftUI
import SwiftData

@MainActor
public final class VideoDetailViewModel: ObservableObject {
    public let video: VideoItem
    @Published public var isBookmarked: Bool = false

    public init(video: VideoItem) {
        self.video = video
    }

    public func checkBookmarkStatus(modelContext: ModelContext) {
        let vID = video.id
        let descriptor = FetchDescriptor<BookmarkEntity>(predicate: #Predicate { $0.videoID == vID })
        if let matches = try? modelContext.fetch(descriptor), !matches.isEmpty {
            isBookmarked = true
        } else {
            isBookmarked = false
        }
    }

    public func toggleBookmark(modelContext: ModelContext) {
        let vID = video.id
        let descriptor = FetchDescriptor<BookmarkEntity>(predicate: #Predicate { $0.videoID == vID })
        if let matches = try? modelContext.fetch(descriptor), let existing = matches.first {
            modelContext.delete(existing)
            isBookmarked = false
        } else {
            let directStr: String?
            let isDirect: Bool
            switch video.mediaSource {
            case .directStream(let url):
                isDirect = true
                directStr = url.absoluteString
            case .youtube:
                isDirect = false
                directStr = nil
            }
            let newBookmark = BookmarkEntity(
                videoID: vID,
                title: video.title,
                channelTitle: video.channelTitle,
                thumbnailURLString: video.thumbnailURL?.absoluteString ?? "",
                isDirectMedia: isDirect,
                directMediaURLString: directStr
            )
            modelContext.insert(newBookmark)
            isBookmarked = true
        }
    }

    public func recordWatchHistory(modelContext: ModelContext, position: Double, duration: Double) {
        let vID = video.id
        let descriptor = FetchDescriptor<WatchHistoryEntity>(predicate: #Predicate { $0.videoID == vID })
        if let matches = try? modelContext.fetch(descriptor), let existing = matches.first {
            existing.lastWatchedDate = Date()
            existing.lastPlaybackPosition = position
            existing.durationSeconds = duration
        } else {
            let history = WatchHistoryEntity(
                videoID: vID,
                title: video.title,
                channelTitle: video.channelTitle,
                thumbnailURLString: video.thumbnailURL?.absoluteString ?? "",
                lastPlaybackPosition: position,
                durationSeconds: duration
            )
            modelContext.insert(history)
        }
    }
}
