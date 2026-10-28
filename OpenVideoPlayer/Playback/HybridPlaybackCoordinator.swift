import Foundation
import AVFoundation
import MediaPlayer
import Combine

public final class HybridPlaybackCoordinator: ObservableObject, PlaybackCoordinatorProtocol {
    @Published public private(set) var state: PlaybackState = .idle
    @Published public private(set) var currentItem: VideoItem?
    @Published public private(set) var currentTime: TimeInterval = 0
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var playbackCommand: PlaybackCommand?

    public let avPlayer = AVPlayer()
    
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var toggleCommandTarget: Any?

    public init() {
        AudioSessionManager.shared.configureAudioSession()
        setupRemoteCommands()
        setupInterruptionHandling()
    }

    public func load(item: VideoItem) {
        self.currentItem = item
        self.currentTime = 0
        self.duration = item.durationSeconds ?? 0
        self.state = .loading
        self.playbackCommand = nil

        switch item.mediaSource {
        case .youtube:
            avPlayer.pause()
            AudioSessionManager.shared.activatePlaybackSession()
        case .directStream(let url):
            guard isValidDirectMediaURL(url) else {
                self.state = .failed("Invalid or unsupported direct media URL scheme. Only HTTP and HTTPS are permitted.")
                return
            }
            AudioSessionManager.shared.activatePlaybackSession()
            let playerItem = AVPlayerItem(url: url)
            avPlayer.replaceCurrentItem(with: playerItem)
            avPlayer.play()
            self.state = .playing(currentTime: 0, duration: duration)
        }

        AudioSessionManager.shared.updateNowPlaying(
            title: item.title,
            channel: item.channelTitle,
            duration: duration,
            currentTime: 0,
            isPlaying: true
        )
    }

    public func updatePlaybackTime(current: TimeInterval, total: TimeInterval) {
        self.currentTime = current
        self.duration = total > 0 ? total : self.duration

        if case .playing = state {
            state = .playing(currentTime: current, duration: duration)
        } else if case .paused = state {
            state = .paused(currentTime: current, duration: duration)
        }

        if let item = currentItem {
            AudioSessionManager.shared.updateNowPlaying(
                title: item.title,
                channel: item.channelTitle,
                duration: duration,
                currentTime: current,
                isPlaying: state.isPlaying
            )
        }
    }

    public func updateState(_ newState: PlaybackState) {
        self.state = newState
        if let item = currentItem {
            AudioSessionManager.shared.updateNowPlaying(
                title: item.title,
                channel: item.channelTitle,
                duration: duration,
                currentTime: currentTime,
                isPlaying: newState.isPlaying
            )
        }
    }

    public func play() {
        guard let item = currentItem else { return }
        playbackCommand = .play
        switch item.mediaSource {
        case .youtube:
            state = .playing(currentTime: currentTime, duration: duration)
        case .directStream:
            avPlayer.play()
            state = .playing(currentTime: currentTime, duration: duration)
        }
    }

    public func pause() {
        guard let item = currentItem else { return }
        playbackCommand = .pause
        switch item.mediaSource {
        case .youtube:
            state = .paused(currentTime: currentTime, duration: duration)
        case .directStream:
            avPlayer.pause()
            state = .paused(currentTime: currentTime, duration: duration)
        }
    }

    public func seek(to seconds: TimeInterval) {
        guard let item = currentItem else { return }
        playbackCommand = .seek(seconds)
        switch item.mediaSource {
        case .youtube:
            self.currentTime = seconds
        case .directStream:
            let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
            avPlayer.seek(to: cmTime)
            self.currentTime = seconds
        }
    }

    public func stop() {
        playbackCommand = .stop
        avPlayer.pause()
        avPlayer.replaceCurrentItem(with: nil)
        currentItem = nil
        currentTime = 0
        duration = 0
        state = .idle
        AudioSessionManager.shared.clearNowPlaying()
        AudioSessionManager.shared.deactivatePlaybackSession()
    }

    private func isValidDirectMediaURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "https" || scheme == "http") && (url.host != nil && !url.host!.isEmpty)
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        playCommandTarget = center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        pauseCommandTarget = center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        toggleCommandTarget = center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.state.isPlaying { self.pause() } else { self.play() }
            return .success
        }
    }

    private func setupInterruptionHandling() {
        AudioSessionManager.shared.onInterruption = { [weak self] shouldResume in
            guard let self = self else { return }
            if shouldResume {
                self.play()
            } else {
                self.pause()
            }
        }
    }

    private func cleanupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        if let target = playCommandTarget { center.playCommand.removeTarget(target) }
        if let target = pauseCommandTarget { center.pauseCommand.removeTarget(target) }
        if let target = toggleCommandTarget { center.togglePlayPauseCommand.removeTarget(target) }
        playCommandTarget = nil
        pauseCommandTarget = nil
        toggleCommandTarget = nil
    }

    deinit {
        cleanupRemoteCommands()
        AudioSessionManager.shared.onInterruption = nil
    }
}
