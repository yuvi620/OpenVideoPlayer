import XCTest
@testable import OpenVideoPlayerCore

final class MockVideoDiscoveryService: VideoDiscoveryService, @unchecked Sendable {
    var searchResultToReturn: SearchResultPage?
    var trendingVideosToReturn: [VideoItem] = []
    var shouldThrow: Error?

    func searchVideos(query: String, pageToken: String?) async throws -> SearchResultPage {
        if let err = shouldThrow { throw err }
        return searchResultToReturn ?? SearchResultPage(items: [], nextPageToken: nil, totalResults: 0)
    }

    func fetchTrendingVideos(regionCode: String) async throws -> [VideoItem] {
        if let err = shouldThrow { throw err }
        return trendingVideosToReturn
    }

    func fetchVideoDetails(videoIDs: [String]) async throws -> [VideoItem] {
        return []
    }
}

@MainActor
final class SearchViewModelTests: XCTestCase {

    func testInitialStateIsIdle() {
        let mockService = MockVideoDiscoveryService()
        let vm = SearchViewModel(service: mockService)
        XCTAssertEqual(vm.state, .idle)
        XCTAssertFalse(vm.isPaginating)
    }

    func testExecuteSearchSuccess() async {
        let mockService = MockVideoDiscoveryService()
        let sampleVideo = VideoItem(
            id: "vid1",
            title: "SwiftUI Tutorial",
            videoDescription: "Learn SwiftUI",
            channelTitle: "Apple Developer",
            channelId: "c1",
            mediaSource: .youtube(videoID: "vid1")
        )
        mockService.searchResultToReturn = SearchResultPage(
            items: [sampleVideo],
            nextPageToken: "token_2",
            totalResults: 1
        )

        let vm = SearchViewModel(service: mockService)
        vm.executeSearch(query: "SwiftUI")

        // Wait brief runloop cycle for Task execution
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(vm.state, .loaded(items: [sampleVideo], hasMore: true))
    }

    func testExecuteSearchEmptyResult() async {
        let mockService = MockVideoDiscoveryService()
        mockService.searchResultToReturn = SearchResultPage(
            items: [],
            nextPageToken: nil,
            totalResults: 0
        )

        let vm = SearchViewModel(service: mockService)
        vm.executeSearch(query: "NonexistentVideoXYZ")

        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(vm.state, .empty(query: "NonexistentVideoXYZ"))
    }

    func testExecuteSearchError() async {
        let mockService = MockVideoDiscoveryService()
        mockService.shouldThrow = VideoDiscoveryError.quotaExceeded

        let vm = SearchViewModel(service: mockService)
        vm.executeSearch(query: "Test")

        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(vm.state, .error(VideoDiscoveryError.quotaExceeded.localizedDescription))
    }

    func testResetSearch() {
        let mockService = MockVideoDiscoveryService()
        let vm = SearchViewModel(service: mockService)
        vm.executeSearch(query: "Test")
        vm.resetSearch()
        XCTAssertEqual(vm.state, .idle)
    }
}
