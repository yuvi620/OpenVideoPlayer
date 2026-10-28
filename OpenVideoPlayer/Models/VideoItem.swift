import Foundation

public struct VideoItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let videoDescription: String
    public let channelTitle: String
    public let channelId: String
    public let publishedAt: Date?
    public let thumbnailURL: URL?
    public let durationSeconds: TimeInterval?
    public let viewCount: Int?
    public let mediaSource: MediaSource

    public enum MediaSource: Hashable, Sendable {
        case youtube(videoID: String)
        case directStream(url: URL)
    }

    public init(
        id: String,
        title: String,
        videoDescription: String,
        channelTitle: String,
        channelId: String,
        publishedAt: Date? = nil,
        thumbnailURL: URL? = nil,
        durationSeconds: TimeInterval? = nil,
        viewCount: Int? = nil,
        mediaSource: MediaSource
    ) {
        self.id = id
        self.title = title
        self.videoDescription = videoDescription
        self.channelTitle = channelTitle
        self.channelId = channelId
        self.publishedAt = publishedAt
        self.thumbnailURL = thumbnailURL
        self.durationSeconds = durationSeconds
        self.viewCount = viewCount
        self.mediaSource = mediaSource
    }
}
