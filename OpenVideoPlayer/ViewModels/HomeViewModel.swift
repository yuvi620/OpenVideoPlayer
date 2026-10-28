import Foundation
import SwiftUI
import Combine

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var state: ViewState = .idle
    @Published public var selectedRegionCode: String = "US"

    public enum ViewState: Equatable {
        case idle
        case loading
        case loaded([VideoItem])
        case error(String)
    }

    private let service: VideoDiscoveryService

    public init(service: VideoDiscoveryService = YouTubeDataAPIService()) {
        self.service = service
    }

    public func loadTrendingVideos() async {
        state = .loading
        do {
            let videos = try await service.fetchTrendingVideos(regionCode: selectedRegionCode)
            state = .loaded(videos)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
