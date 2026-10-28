import SwiftUI
import AVFoundation

public struct PlayerView: View {
    public let video: VideoItem
    @ObservedObject public var coordinator: HybridPlaybackCoordinator

    public init(video: VideoItem, coordinator: HybridPlaybackCoordinator) {
        self.video = video
        self.coordinator = coordinator
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch video.mediaSource {
            case .youtube(let vID):
                YouTubeIFramePlayerView(
                    videoID: vID,
                    state: Binding(
                        get: { coordinator.state },
                        set: { coordinator.updateState($0) }
                    ),
                    command: coordinator.playbackCommand,
                    onTimeUpdate: { cur, dur in
                        coordinator.updatePlaybackTime(current: cur, total: dur)
                    }
                )
            case .directStream(let url):
                DirectMediaAVPlayerView(
                    mediaURL: url,
                    player: coordinator.avPlayer,
                    onTimeUpdate: { cur, dur in
                        coordinator.updatePlaybackTime(current: cur, total: dur)
                    }
                )
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
}
