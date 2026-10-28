# OpenVideoPlayer: Clean-Room iOS Video Client

OpenVideoPlayer is a clean-room, independently architected SwiftUI video player application for iOS 17+.

It is engineered based on architectural specifications and capability matrices derived from reverse-engineering studies of modern iOS streaming video clients, while strictly adhering to public APIs, standard platform frameworks, and terms of service.

---

## 1. Architectural Highlights

| Subsystem | YouTube iOS Architecture (Reversed) | OpenVideoPlayer Architecture (Clean-Room) |
| :--- | :--- | :--- |
| **Video Discovery** | Proprietary Protobuf browse RPCs (`/youtubei/v1/browse`) | **YouTube Data API v3** (`/v3/search`, `/v3/videos`) via `URLSession` |
| **Video Playback** | Google HAM (chunked DASH/FMP4 over Cronet HTTP/3) | **Hybrid Engine**: `WKWebView` + YouTube IFrame API (hosted) & `AVPlayer` (direct) |
| **Background Audio** | `AVAudioSession` + Cronet stream pipeline (Premium gated) | **Native `AVAudioSession`** (`.playback`, `MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`) |
| **Picture-in-Picture**| `AVPictureInPictureController` / `MLAVPlayer` (gated) | **Native PiP**: `AVPlayerViewController` and WebKit PiP (`allowsPictureInPictureMediaPlayback`) |
| **Local Persistence** | Proprietary SQLite cache / LevelDB (`YTCache`) | **Apple SwiftData** (`@Model` for bookmarks and watch history) |
| **UI Framework** | Google Elements (ObjC/C++ declarative UI runtime) | **Pure Apple SwiftUI** + NavigationStack + async/await |
| **Monetization/DRM** | Google YPC, AdSlot DAI, `widevine_cdm_secured_ios` | **None** (Terms-compliant, zero proprietary binaries, zero DRM tampering) |

---

## 2. Project Structure

```
OpenVideoPlayer/
├── Package.swift                                # SwiftPM Package manifest
├── OpenVideoPlayer.xcodeproj/
│   └── project.pbxproj                          # Xcode project definition
├── OpenVideoPlayer/
│   ├── App/
│   │   └── OpenVideoPlayerApp.swift             # App entry point with SwiftData container
│   ├── Models/
│   │   ├── VideoItem.swift                      # Clean domain model
│   │   ├── YouTubeAPIModels.swift               # Codable DTOs for YouTube Data API v3
│   │   ├── BookmarkEntity.swift                 # SwiftData entity for bookmarks
│   │   └── WatchHistoryEntity.swift             # SwiftData entity for playback history
│   ├── Services/
│   │   ├── APIConfiguration.swift               # Key management (Config.plist / env)
│   │   ├── VideoDiscoveryService.swift          # Protocol definition & error types
│   │   └── YouTubeDataAPIService.swift          # Live API client with caching & fallback
│   ├── Playback/
│   │   ├── PlaybackCoordinator.swift            # Playback state & coordinator protocols
│   │   ├── AudioSessionManager.swift            # AVAudioSession & Now Playing integration
│   │   ├── YouTubeIFramePlayerView.swift        # WKWebView wrapper for YouTube IFrame API
│   │   ├── DirectMediaAVPlayerView.swift        # AVPlayerViewController wrapper (MP4/HLS)
│   │   └── HybridPlaybackCoordinator.swift      # Unified controller across both engines
│   ├── ViewModels/
│   │   ├── HomeViewModel.swift                  # Trending videos state machine
│   │   ├── SearchViewModel.swift                # Debounced search & pagination
│   │   ├── VideoDetailViewModel.swift           # Metadata, related videos, bookmarks
│   │   └── LibraryViewModel.swift               # Watch history & saved bookmarks
│   ├── Views/
│   │   ├── Components/
│   │   │   ├── VideoCardView.swift              # Thumbnail, duration badge, title, channel
│   │   │   └── StateViews.swift                 # LoadingSpinner, ErrorView, EmptyStateView
│   │   ├── HomeView.swift                       # Trending feed with pull-to-refresh
│   │   ├── SearchView.swift                     # Search input, results, pagination
│   │   ├── PlayerView.swift                     # Hybrid player view container
│   │   ├── VideoDetailView.swift                # Player + metadata + description + actions
│   │   ├── LibraryView.swift                    # Saved bookmarks & history with swipe-to-delete
│   │   └── MainTabView.swift                    # 3-tab navigation (Trending, Search, Library)
│   └── Resources/
│       ├── Info.plist                           # Background audio mode, orientations, bundle ID
│       ├── Config.plist.template                # API key template
│       └── Assets.xcassets/                     # AppIcon and AccentColor
└── README.md                                    # Architecture & build instructions
```

---

## 3. Configuration

### YouTube Data API v3 Key Setup
To enable live video discovery and search:
1. Obtain an API key from the [Google Cloud Console](https://console.cloud.google.com/) with YouTube Data API v3 enabled.
2. In `OpenVideoPlayer/Resources/`, copy `Config.plist.template` to `Config.plist`:
   ```bash
   cp OpenVideoPlayer/Resources/Config.plist.template OpenVideoPlayer/Resources/Config.plist
   ```
3. Open `Config.plist` and insert your API key:
   ```xml
   <key>YouTubeAPIKey</key>
   <string>AIzaSyYourActualKeyHere...</string>
   ```
*Note: If no API key is provided, the application automatically supplies mock video items so navigation, player views, and local persistence can be tested without network credentials.*

---

## 4. Development Environment & Build Instructions

### Environment Notice
This project repository was synthesized on a Linux development host (`Ubuntu 26.04.1 LTS`). As macOS developer tools (`xcodebuild`, `xcrun`, `simctl`, and the iOS SDK) are proprietary to Apple and exclusively available on macOS:
- The project **has not been compiled or tested on Linux**.
- Complete Xcode project files and Swift sources are provided and structured for immediate import into macOS.

### Building on macOS with Xcode
Requirements:
- macOS Sonoma 14.0 or newer
- Xcode 15.0 or newer
- iOS 17.0+ SDK (Simulator or physical device)

#### Option A: Using Xcode GUI
1. Clone or copy this directory to your Mac.
2. Double-click `OpenVideoPlayer.xcodeproj` to open it in Xcode.
3. Select an iOS 17+ Simulator (e.g., iPhone 15 Pro) from the scheme dropdown.
4. Press `Cmd + R` to build and run.

#### Option B: Using the Command Line (`xcodebuild`)
Open Terminal on your Mac and run:
```bash
# List available simulator destinations
xcodebuild -scheme OpenVideoPlayer -showdestinations

# Build the project for the iOS Simulator
xcodebuild build \
  -project OpenVideoPlayer.xcodeproj \
  -scheme OpenVideoPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5' \
  -configuration Debug
```

#### Option C: Swift Package Manager
The core components are also configured as a Swift Package:
```bash
swift build
```

---

## 5. Verification & Testing Guide

Once opened on macOS with Xcode:

1. **Discovery & Search Verification:**
   - Launch app on Simulator. Verify Trending tab displays cards with titles, thumbnails, and channel names.
   - Switch to Search tab. Enter queries (e.g. "SwiftUI") and verify results load.
   - Test pull-to-refresh on HomeView.
2. **Playback Verification:**
   - Tap any video. Verify `VideoDetailView` displays the player in the upper region.
   - Confirm player states: loading, playing, pausing, buffering.
   - Test full-screen / orientation changes (portrait and landscape).
3. **Background Audio & Lock Screen:**
   - Start playback. Send app to background (`Cmd + Shift + H`).
   - Verify audio continues playing.
   - Open Simulator Control Center / Lock Screen to confirm title, channel name, and remote play/pause buttons respond.
4. **SwiftData Persistence:**
   - Tap the Bookmark button on a video. Switch to Library tab; verify bookmark appears.
   - Verify watch history updates automatically with accurate watch timestamps.
   - Test swipe-to-delete on individual history items and "Clear All" button.
