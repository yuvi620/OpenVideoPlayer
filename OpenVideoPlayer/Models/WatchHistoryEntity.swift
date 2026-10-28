import Foundation
import SwiftData

@Model
public final class WatchHistoryEntity {
    @Attribute(.unique) public var videoID: String
    public var title: String
    public var channelTitle: String
    public var thumbnailURLString: String
    public var lastWatchedDate: Date
    public var lastPlaybackPosition: Double
    public var durationSeconds: Double
    public var isDirectMedia: Bool
    public var directMediaURLString: String?

    public init(
        videoID: String,
        title: String,
        channelTitle: String,
        thumbnailURLString: String,
        lastPlaybackPosition: Double = 0.0,
        durationSeconds: Double = 0.0,
        isDirectMedia: Bool = false,
        directMediaURLString: String? = nil
    ) {
        self.videoID = videoID
        self.title = title
        self.channelTitle = channelTitle
        self.thumbnailURLString = thumbnailURLString
        self.lastWatchedDate = Date()
        self.lastPlaybackPosition = lastPlaybackPosition
        self.durationSeconds = durationSeconds
        self.isDirectMedia = isDirectMedia
        self.directMediaURLString = directMediaURLString
    }

    public var progressFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(max(lastPlaybackPosition / durationSeconds, 0.0), 1.0)
    }

    public func toVideoItem() -> VideoItem {
        let thumbURL = URL(string: thumbnailURLString)
        let source: VideoItem.MediaSource
        if isDirectMedia, let directStr = directMediaURLString, let dURL = URL(string: directStr) {
            source = .directStream(url: dURL)
        } else {
            source = .youtube(videoID: videoID)
        }
        return VideoItem(
            id: videoID,
            title: title,
            videoDescription: "",
            channelTitle: channelTitle,
            channelId: "",
            publishedAt: lastWatchedDate,
            thumbnailURL: thumbURL,
            durationSeconds: durationSeconds,
            mediaSource: source
        )
    }
}
