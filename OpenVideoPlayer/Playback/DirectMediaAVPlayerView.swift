import SwiftUI
import AVKit

public struct DirectMediaAVPlayerView: UIViewControllerRepresentable {
    public let mediaURL: URL
    public let player: AVPlayer
    public let onTimeUpdate: (TimeInterval, TimeInterval) -> Void

    public init(
        mediaURL: URL,
        player: AVPlayer,
        onTimeUpdate: @escaping (TimeInterval, TimeInterval) -> Void
    ) {
        self.mediaURL = mediaURL
        self.player = player
        self.onTimeUpdate = onTimeUpdate
    }

    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = AVPictureInPictureController.isPictureInPictureSupported()
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.showsPlaybackControls = true

        context.coordinator.setupPeriodicTimeObserver(player: player)
        return controller
    }

    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            context.coordinator.cleanupTimeObserver()
            uiViewController.player = player
            context.coordinator.setupPeriodicTimeObserver(player: player)
        }
    }

    public static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.cleanupTimeObserver()
        uiViewController.delegate = nil
        uiViewController.player = nil
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var parent: DirectMediaAVPlayerView
        var timeObserverToken: Any?
        weak var observedPlayer: AVPlayer?

        init(_ parent: DirectMediaAVPlayerView) {
            self.parent = parent
        }

        func setupPeriodicTimeObserver(player: AVPlayer) {
            cleanupTimeObserver()
            observedPlayer = player
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                let cur = time.seconds
                let dur = player.currentItem?.duration.seconds ?? 0
                if cur.isFinite && dur.isFinite {
                    self.parent.onTimeUpdate(cur, dur)
                }
            }
        }

        func cleanupTimeObserver() {
            if let token = timeObserverToken, let player = observedPlayer {
                player.removeTimeObserver(token)
            }
            timeObserverToken = nil
            observedPlayer = nil
        }

        deinit {
            cleanupTimeObserver()
        }

        // MARK: - AVPlayerViewControllerDelegate
        public func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            // Picture-in-Picture active
        }

        public func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            // Picture-in-Picture dismissed
        }

        public func playerViewController(
            _ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(true)
        }
    }
}
