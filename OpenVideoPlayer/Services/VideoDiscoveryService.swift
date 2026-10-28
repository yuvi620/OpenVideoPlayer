import Foundation

public protocol VideoDiscoveryService: Sendable {
    func searchVideos(query: String, pageToken: String?) async throws -> SearchResultPage
    func fetchTrendingVideos(regionCode: String) async throws -> [VideoItem]
    func fetchVideoDetails(videoIDs: [String]) async throws -> [VideoItem]
}

public enum VideoDiscoveryError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case quotaExceeded
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No YouTube Data API key configured. Please add your key in Config.plist or App Settings."
        case .invalidURL:
            return "Unable to construct a valid URL for the request."
        case .quotaExceeded:
            return "YouTube API daily quota exceeded. You can supply a personal API key in Settings."
        case .networkError(let err):
            return "Network connection failed: \(err.localizedDescription)"
        case .serverError(let code, let msg):
            return "YouTube API error (\(code)): \(msg)"
        case .decodingError(let err):
            return "Failed to parse API response: \(err.localizedDescription)"
        }
    }
}
