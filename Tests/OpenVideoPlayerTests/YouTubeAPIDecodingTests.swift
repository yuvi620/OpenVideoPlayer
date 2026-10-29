import XCTest
@testable import OpenVideoPlayer

final class YouTubeAPIDecodingTests: XCTestCase {

    func testSearchListResponseDecoding() throws {
        let json = """
        {
            "kind": "youtube#searchListResponse",
            "nextPageToken": "CAUQAA",
            "pageInfo": {
                "totalResults": 1000,
                "resultsPerPage": 1
            },
            "items": [
                {
                    "id": {
                        "kind": "youtube#video",
                        "videoId": "dQw4w9WgXcQ"
                    },
                    "snippet": {
                        "publishedAt": "2009-10-25T06:57:33Z",
                        "channelId": "UCuAXFkgsw1L7xaCfnd5JJOw",
                        "title": "Rick Astley - Never Gonna Give You Up",
                        "description": "The official video for Never Gonna Give You Up",
                        "channelTitle": "Rick Astley",
                        "thumbnails": {
                            "high": {
                                "url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
                                "width": 480,
                                "height": 360
                            }
                        }
                    }
                }
            ]
        }
        """

        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(YouTubeSearchListResponse.self, from: data)

        XCTAssertEqual(response.items.count, 1)
        XCTAssertEqual(response.nextPageToken, "CAUQAA")
        let item = response.items.first
        XCTAssertEqual(item?.id.videoId, "dQw4w9WgXcQ")
        XCTAssertEqual(item?.snippet.title, "Rick Astley - Never Gonna Give You Up")
        XCTAssertEqual(item?.snippet.channelTitle, "Rick Astley")
    }

    func testVideoListResponseDecoding() throws {
        let json = """
        {
            "kind": "youtube#videoListResponse",
            "items": [
                {
                    "id": "dQw4w9WgXcQ",
                    "snippet": {
                        "publishedAt": "2009-10-25T06:57:33Z",
                        "channelId": "UCuAXFkgsw1L7xaCfnd5JJOw",
                        "title": "Rick Astley - Never Gonna Give You Up",
                        "description": "Official Video",
                        "channelTitle": "Rick Astley"
                    },
                    "contentDetails": {
                        "duration": "PT3M33S"
                    },
                    "statistics": {
                        "viewCount": "1500000000"
                    }
                }
            ]
        }
        """

        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(YouTubeVideoListResponse.self, from: data)

        XCTAssertEqual(response.items.count, 1)
        let item = response.items.first
        XCTAssertEqual(item?.id, "dQw4w9WgXcQ")
        XCTAssertEqual(item?.contentDetails?.duration, "PT3M33S")
        XCTAssertEqual(item?.statistics?.viewCount, "1500000000")
    }

    func testISO8601DurationParsing() {
        func parseISO8601Duration(_ str: String) -> TimeInterval? {
            var duration: TimeInterval = 0
            var tempNumber = ""
            for char in str {
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

        XCTAssertEqual(parseISO8601Duration("PT3M33S"), 213)
        XCTAssertEqual(parseISO8601Duration("PT1H2M30S"), 3750)
        XCTAssertEqual(parseISO8601Duration("PT45S"), 45)
        XCTAssertEqual(parseISO8601Duration("PT10M"), 600)
        XCTAssertNil(parseISO8601Duration("INVALID"))
    }
}
