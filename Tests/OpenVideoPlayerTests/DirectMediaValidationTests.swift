import XCTest
@testable import OpenVideoPlayerCore

final class DirectMediaValidationTests: XCTestCase {

    func testURLValidation() {
        func isValidDirectMediaURL(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased() else { return false }
            return (scheme == "https" || scheme == "http") && (url.host != nil && !url.host!.isEmpty)
        }

        XCTAssertTrue(isValidDirectMediaURL(URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!))
        XCTAssertTrue(isValidDirectMediaURL(URL(string: "http://devstreaming.apple.com/videos/sample.m3u8")!))
        XCTAssertFalse(isValidDirectMediaURL(URL(string: "file:///etc/passwd")!))
        XCTAssertFalse(isValidDirectMediaURL(URL(string: "javascript:alert(1)")!))
        XCTAssertFalse(isValidDirectMediaURL(URL(string: "data:text/html,test")!))
    }

    func testYouTubeVideoIDValidation() {
        func isValidVideoID(_ id: String) -> Bool {
            let pattern = "^[a-zA-Z0-9_-]{5,32}$"
            return id.range(of: pattern, options: .regularExpression) != nil
        }

        XCTAssertTrue(isValidVideoID("dQw4w9WgXcQ"))
        XCTAssertTrue(isValidVideoID("M7lc1UVf-VE"))
        XCTAssertFalse(isValidVideoID("'; alert(1); //"))
        XCTAssertFalse(isValidVideoID("<script>"))
        XCTAssertFalse(isValidVideoID("short")) // 5 chars is valid, let's test 2 chars
        XCTAssertFalse(isValidVideoID("ab"))
    }
}
