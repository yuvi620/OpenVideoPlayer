import Foundation

public enum APIConfiguration {
    public static var youTubeAPIKey: String {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["YouTubeAPIKey"] as? String,
           !key.isEmpty,
           key != "YOUR_YOUTUBE_API_KEY_HERE" {
            return key
        }

        if let userKey = UserDefaults.standard.string(forKey: "OpenVideoPlayer_UserAPIKey"),
           !userKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return userKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let envKey = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        return ""
    }

    public static var hasValidAPIKey: Bool {
        return !youTubeAPIKey.isEmpty
    }
}
