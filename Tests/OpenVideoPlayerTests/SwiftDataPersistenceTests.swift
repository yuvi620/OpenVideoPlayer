import XCTest
import SwiftData
@testable import OpenVideoPlayerCore

final class SwiftDataPersistenceTests: XCTestCase {

    func testBookmarkEntityMapping() {
        let bookmark = BookmarkEntity(
            videoID: "abc12345",
            title: "WWDC Keynote",
            channelTitle: "Apple",
            thumbnailURLString: "https://example.com/thumb.jpg",
            isDirectMedia: false,
            userNotes: "Important developer session"
        )

        let video = bookmark.toVideoItem()
        XCTAssertEqual(video.id, "abc12345")
        XCTAssertEqual(video.title, "WWDC Keynote")
        XCTAssertEqual(video.channelTitle, "Apple")
        XCTAssertEqual(video.mediaSource, .youtube(videoID: "abc12345"))
    }

    func testWatchHistoryProgressFraction() {
        let hist = WatchHistoryEntity(
            videoID: "xyz789",
            title: "Direct Stream Video",
            channelTitle: "Open Media",
            thumbnailURLString: "https://example.com/thumb.jpg",
            lastPlaybackPosition: 50.0,
            durationSeconds: 100.0,
            isDirectMedia: true,
            directMediaURLString: "https://example.com/video.mp4"
        )

        XCTAssertEqual(hist.progressFraction, 0.5, accuracy: 0.001)

        let video = hist.toVideoItem()
        XCTAssertEqual(video.id, "xyz789")
        if case .directStream(let url) = video.mediaSource {
            XCTAssertEqual(url.absoluteString, "https://example.com/video.mp4")
        } else {
            XCTFail("Expected directStream mediaSource")
        }
    }

    func testWatchHistoryZeroDurationClamping() {
        let hist = WatchHistoryEntity(
            videoID: "zero",
            title: "Zero Duration",
            channelTitle: "Channel",
            thumbnailURLString: "",
            lastPlaybackPosition: 10.0,
            durationSeconds: 0.0
        )

        XCTAssertEqual(hist.progressFraction, 0.0)
    }
}
