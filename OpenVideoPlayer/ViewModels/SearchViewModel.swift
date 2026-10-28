import Foundation
import SwiftUI
import Combine

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var queryText: String = ""
    @Published public private(set) var state: SearchState = .idle
    @Published public private(set) var isPaginating: Bool = false

    public enum SearchState: Equatable {
        case idle
        case loading
        case loaded(items: [VideoItem], hasMore: Bool)
        case empty(query: String)
        case error(String)
    }

    private let service: VideoDiscoveryService
    private var nextPageToken: String?
    private var currentSearchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    public init(service: VideoDiscoveryService = YouTubeDataAPIService()) {
        self.service = service
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $queryText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self.resetSearch()
                } else {
                    self.executeSearch(query: trimmed)
                }
            }
            .store(in: &cancellables)
    }

    public func executeSearch(query: String) {
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            state = .loading
            nextPageToken = nil
            do {
                let result = try await service.searchVideos(query: query, pageToken: nil)
                guard !Task.isCancelled else { return }
                if result.items.isEmpty {
                    state = .empty(query: query)
                } else {
                    self.nextPageToken = result.nextPageToken
                    state = .loaded(items: result.items, hasMore: result.nextPageToken != nil)
                }
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(error.localizedDescription)
            }
        }
    }

    public func loadNextPage() async {
        guard let token = nextPageToken, !token.isEmpty, !isPaginating else { return }
        guard case .loaded(let currentItems, _) = state else { return }

        isPaginating = true
        do {
            let result = try await service.searchVideos(query: queryText, pageToken: token)
            self.nextPageToken = result.nextPageToken
            let combined = currentItems + result.items
            state = .loaded(items: combined, hasMore: result.nextPageToken != nil)
            isPaginating = false
        } catch {
            isPaginating = false
        }
    }

    public func resetSearch() {
        currentSearchTask?.cancel()
        state = .idle
        nextPageToken = nil
    }
}
