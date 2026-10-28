import Foundation
import SwiftData

@Model
public final class BookmarkEntity {
    @Attribute(.unique) public var videoID: String
    public var title: String
    public var channelTitle: String
    public var thumbnailURLString: String
    public var dateAdded: Date
    public var isDirectMedia: Bool
    public var directMediaURLString: String?
    public var userNotes: String?

    public init(
        videoID: String,
        title: String,
        channelTitle: String,
        thumbnailURLString: String,
        isDirectMedia: Bool = false,
        directMediaURLString: String? = nil,
        userNotes: String? = nil
    ) {
        self.videoID = videoID
        self.title = title
        self.channelTitle = channelTitle
        self.thumbnailURLString = thumbnailURLString
        self.dateAdded = Date()
        self.isDirectMedia = isDirectMedia
        self.directMediaURLString = directMediaURLString
        self.userNotes = userNotes
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
            videoDescription: userNotes ?? "",
            channelTitle: channelTitle,
            channelId: "",
            publishedAt: dateAdded,
            thumbnailURL: thumbURL,
            mediaSource: source
        )
    }
}
