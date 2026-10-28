import Foundation

public final class YouTubeDataAPIService: VideoDiscoveryService {
    private let session: URLSession
    private let baseURL = URL(string: "https://www.googleapis.com/youtube/v3")!
    
    private let cache = NSCache<NSString, CacheEntry>()

    private final class CacheEntry: @unchecked Sendable {
        let page: SearchResultPage
        let timestamp: Date
        init(page: SearchResultPage) {
            self.page = page
            self.timestamp = Date()
        }
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 1800
        }
    }

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func searchVideos(query: String, pageToken: String? = nil) async throws -> SearchResultPage {
        let key = APIConfiguration.youTubeAPIKey
        guard !key.isEmpty else {
            // When API key is not configured, supply matching offline sample items for testing
            return sampleSearchFallback(query: query)
        }

        let cacheKey = NSString(string: "search_\(query.lowercased())_\(pageToken ?? "first")")
        if let cached = cache.object(forKey: cacheKey), cached.isValid {
            return cached.page
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: true)!
        var queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "key", value: key)
        ]
        if let token = pageToken, !token.isEmpty {
            queryItems.append(URLQueryItem(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw VideoDiscoveryError.invalidURL }

        do {
            let (data, response) = try await session.data(from: url)
            try validateHTTPResponse(response, data: data)

            let searchResponse = try JSONDecoder().decode(YouTubeSearchListResponse.self, from: data)
            let videoIDs = searchResponse.items.compactMap { $0.id.videoId }
            let detailedMap = try await fetchDetailsMap(videoIDs: videoIDs, key: key)

            var items: [VideoItem] = []
            for item in searchResponse.items {
                guard let vID = item.id.videoId else { continue }
                let snippet = item.snippet
                let thumbStr = snippet.thumbnails?.high?.url ?? snippet.thumbnails?.medium?.url
                let thumbURL = thumbStr != nil ? URL(string: thumbStr!) : nil
                
                let detail = detailedMap[vID]
                let duration = detail?.contentDetails?.duration.flatMap(parseISO8601Duration)
                let viewCount = detail?.statistics?.viewCount.flatMap(Int.init)

                let video = VideoItem(
                    id: vID,
                    title: snippet.title ?? "Untitled Video",
                    videoDescription: snippet.description ?? "",
                    channelTitle: snippet.channelTitle ?? "Unknown Channel",
                    channelId: snippet.channelId ?? "",
                    publishedAt: snippet.publishedAt.flatMap(parseDate),
                    thumbnailURL: thumbURL,
                    durationSeconds: duration,
                    viewCount: viewCount,
                    mediaSource: .youtube(videoID: vID)
                )
                items.append(video)
            }

            let resultPage = SearchResultPage(
                items: items,
                nextPageToken: searchResponse.nextPageToken,
                totalResults: searchResponse.pageInfo?.totalResults
            )

            cache.setObject(CacheEntry(page: resultPage), forKey: cacheKey)
            return resultPage
        } catch let err as VideoDiscoveryError {
            throw err
        } catch let err as DecodingError {
            throw VideoDiscoveryError.decodingError(err)
        } catch {
            throw VideoDiscoveryError.networkError(error)
        }
    }

    public func fetchTrendingVideos(regionCode: String = "US") async throws -> [VideoItem] {
        let key = APIConfiguration.youTubeAPIKey
        guard !key.isEmpty else {
            // When API key is not configured, supply curated sample items for testing
            return sampleTrendingVideos()
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("videos"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "chart", value: "mostPopular"),
            URLQueryItem(name: "regionCode", value: regionCode),
            URLQueryItem(name: "maxResults", value: "25"),
            URLQueryItem(name: "key", value: key)
        ]

        guard let url = components.url else { throw VideoDiscoveryError.invalidURL }

        let (data, response) = try await session.data(from: url)
        try validateHTTPResponse(response, data: data)

        let videoListResponse = try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
        return videoListResponse.items.map { item in
            let snippet = item.snippet
            let thumbStr = snippet.thumbnails?.high?.url ?? snippet.thumbnails?.medium?.url
            let thumbURL = thumbStr != nil ? URL(string: thumbStr!) : nil
            let duration = item.contentDetails?.duration.flatMap(parseISO8601Duration)
            let viewCount = item.statistics?.viewCount.flatMap(Int.init)

            return VideoItem(
                id: item.id,
                title: snippet.title ?? "Untitled Video",
                videoDescription: snippet.description ?? "",
                channelTitle: snippet.channelTitle ?? "Unknown Channel",
                channelId: snippet.channelId ?? "",
                publishedAt: snippet.publishedAt.flatMap(parseDate),
                thumbnailURL: thumbURL,
                durationSeconds: duration,
                viewCount: viewCount,
                mediaSource: .youtube(videoID: item.id)
            )
        }
    }

    public func fetchVideoDetails(videoIDs: [String]) async throws -> [VideoItem] {
        guard !videoIDs.isEmpty else { return [] }
        let key = APIConfiguration.youTubeAPIKey
        guard !key.isEmpty else {
            return sampleTrendingVideos().filter { videoIDs.contains($0.id) }
        }
        let map = try await fetchDetailsMap(videoIDs: videoIDs, key: key)
        return videoIDs.compactMap { vID in
            guard let item = map[vID] else { return nil }
            let snippet = item.snippet
            let thumbStr = snippet.thumbnails?.high?.url ?? snippet.thumbnails?.medium?.url
            return VideoItem(
                id: item.id,
                title: snippet.title ?? "Untitled",
                videoDescription: snippet.description ?? "",
                channelTitle: snippet.channelTitle ?? "",
                channelId: snippet.channelId ?? "",
                publishedAt: snippet.publishedAt.flatMap(parseDate),
                thumbnailURL: thumbStr != nil ? URL(string: thumbStr!) : nil,
                durationSeconds: item.contentDetails?.duration.flatMap(parseISO8601Duration),
                viewCount: item.statistics?.viewCount.flatMap(Int.init),
                mediaSource: .youtube(videoID: item.id)
            )
        }
    }

    private func fetchDetailsMap(videoIDs: [String], key: String) async throws -> [String: YouTubeVideoListResponse.VideoDetailItem] {
        guard !videoIDs.isEmpty else { return [:] }
        var components = URLComponents(url: baseURL.appendingPathComponent("videos"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "id", value: videoIDs.joined(separator: ",")),
            URLQueryItem(name: "key", value: key)
        ]
        guard let url = components.url else { return [:] }

        let (data, response) = try await session.data(from: url)
        try validateHTTPResponse(response, data: data)

        let resp = try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)
        var map: [String: YouTubeVideoListResponse.VideoDetailItem] = [:]
        for item in resp.items { map[item.id] = item }
        return map
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 403 {
            if let str = String(data: data, encoding: .utf8), str.contains("quotaExceeded") {
                throw VideoDiscoveryError.quotaExceeded
            }
            throw VideoDiscoveryError.serverError(statusCode: 403, message: "Forbidden or Quota Exceeded")
        }
        if http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw VideoDiscoveryError.serverError(statusCode: http.statusCode, message: msg)
        }
    }

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: str)
    }

    private func parseISO8601Duration(_ durationString: String) -> TimeInterval? {
        var duration: TimeInterval = 0
        var tempNumber = ""
        for char in durationString {
            if char.isNumber {
                tempNumber.append(char)
            } else if let num = Double(tempNumber) {
                switch char {
                case "H": duration += num * 3600
                case "M": duration += num * 60
                case "S": duration += num
                default: break
                }
                tempNumber = ""
            }
        }
        return duration > 0 ? duration : nil
    }

    // MARK: - Offline / Credential-free Sample Data for Physical Device Testing
    private func sampleTrendingVideos() -> [VideoItem] {
        return [
            VideoItem(
                id: "M7lc1UVf-VE",
                title: "YouTube Developers Live - Embedded Player API",
                videoDescription: "Demonstration of YouTube HTML5 embedded player capabilities and JavaScript control bridge.",
                channelTitle: "Google Developers",
                channelId: "UC_x5XG1OV2P6uZZ5FSM9Ttw",
                publishedAt: Date(timeIntervalSinceNow: -86400 * 30),
                thumbnailURL: URL(string: "https://i.ytimg.com/vi/M7lc1UVf-VE/hqdefault.jpg"),
                durationSeconds: 278,
                viewCount: 1420500,
                mediaSource: .youtube(videoID: "M7lc1UVf-VE")
            ),
            VideoItem(
                id: "direct_sample_bbb",
                title: "Big Buck Bunny (Direct HLS Stream)",
                videoDescription: "Open-source direct media HLS stream demonstrating native iOS Picture-in-Picture, background audio, and AVPlayer integration.",
                channelTitle: "Blender Foundation",
                channelId: "blender_org",
                publishedAt: Date(timeIntervalSinceNow: -86400 * 60),
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg"),
                durationSeconds: 596,
                viewCount: 8520000,
                mediaSource: .directStream(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!)
            ),
            VideoItem(
                id: "dQw4w9WgXcQ",
                title: "Rick Astley - Never Gonna Give You Up (Official Video)",
                videoDescription: "The official video for Never Gonna Give You Up by Rick Astley.",
                channelTitle: "Rick Astley",
                channelId: "UCuAXFkgsw1L7xaCfnd5JJOw",
                publishedAt: Date(timeIntervalSinceNow: -86400 * 365),
                thumbnailURL: URL(string: "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"),
                durationSeconds: 213,
                viewCount: 1540000000,
                mediaSource: .youtube(videoID: "dQw4w9WgXcQ")
            ),
            VideoItem(
                id: "direct_sample_tears",
                title: "Tears of Steel (Direct Media MP4)",
                videoDescription: "VFX open movie direct media stream demonstrating lock screen Now Playing metadata and remote transport controls.",
                channelTitle: "Blender Foundation",
                channelId: "blender_org",
                publishedAt: Date(timeIntervalSinceNow: -86400 * 90),
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg"),
                durationSeconds: 734,
                viewCount: 4230000,
                mediaSource: .directStream(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")!)
            )
        ]
    }

    private func sampleSearchFallback(query: String) -> SearchResultPage {
        let all = sampleTrendingVideos()
        let q = query.lowercased()
        let filtered = all.filter {
            $0.title.lowercased().contains(q) ||
            $0.videoDescription.lowercased().contains(q) ||
            $0.channelTitle.lowercased().contains(q)
        }
        return SearchResultPage(
            items: filtered.isEmpty ? all : filtered,
            nextPageToken: nil,
            totalResults: filtered.isEmpty ? all.count : filtered.count
        )
    }
}
