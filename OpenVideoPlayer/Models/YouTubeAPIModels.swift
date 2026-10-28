import Foundation

public struct YouTubeSearchListResponse: Codable, Sendable {
    public let kind: String?
    public let nextPageToken: String?
    public let prevPageToken: String?
    public let pageInfo: PageInfo?
    public let items: [SearchItem]

    public struct PageInfo: Codable, Sendable {
        public let totalResults: Int?
        public let resultsPerPage: Int?
    }

    public struct SearchItem: Codable, Sendable {
        public let id: ResourceID
        public let snippet: Snippet

        public struct ResourceID: Codable, Sendable {
            public let kind: String?
            public let videoId: String?
            public let channelId: String?
            public let playlistId: String?
        }

        public struct Snippet: Codable, Sendable {
            public let publishedAt: String?
            public let channelId: String?
            public let title: String?
            public let description: String?
            public let channelTitle: String?
            public let thumbnails: Thumbnails?
        }
    }
}

public struct YouTubeVideoListResponse: Codable, Sendable {
    public let kind: String?
    public let nextPageToken: String?
    public let items: [VideoDetailItem]

    public struct VideoDetailItem: Codable, Sendable {
        public let id: String
        public let snippet: Snippet
        public let contentDetails: ContentDetails?
        public let statistics: Statistics?

        public struct Snippet: Codable, Sendable {
            public let publishedAt: String?
            public let channelId: String?
            public let title: String?
            public let description: String?
            public let channelTitle: String?
            public let thumbnails: Thumbnails?
            public let tags: [String]?
            public let categoryId: String?
        }

        public struct ContentDetails: Codable, Sendable {
            public let duration: String?
            public let definition: String?
            public let caption: String?
        }

        public struct Statistics: Codable, Sendable {
            public let viewCount: String?
            public let likeCount: String?
            public let commentCount: String?
        }
    }
}

public struct Thumbnails: Codable, Sendable {
    public let defaultThumbnail: ThumbnailInfo?
    public let medium: ThumbnailInfo?
    public let high: ThumbnailInfo?
    public let standard: ThumbnailInfo?
    public let maxres: ThumbnailInfo?

    enum CodingKeys: String, CodingKey {
        case defaultThumbnail = "default"
        case medium
        case high
        case standard
        case maxres
    }

    public struct ThumbnailInfo: Codable, Sendable {
        public let url: String
        public let width: Int?
        public let height: Int?
    }
}

public struct SearchResultPage: Sendable {
    public let items: [VideoItem]
    public let nextPageToken: String?
    public let totalResults: Int?

    public init(items: [VideoItem], nextPageToken: String?, totalResults: Int?) {
        self.items = items
        self.nextPageToken = nextPageToken
        self.totalResults = totalResults
    }
}
