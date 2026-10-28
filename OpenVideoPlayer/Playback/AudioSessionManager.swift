import Foundation
import AVFoundation
import MediaPlayer
import UIKit

public final class AudioSessionManager {
    public static let shared = AudioSessionManager()
    
    public var onInterruption: ((Bool) -> Void)?
    private var isConfigured = false

    private init() {
        setupInterruptionObserver()
    }

    public func configureAudioSession() {
        guard !isConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            isConfigured = true
        } catch {
            print("AudioSessionManager: Failed to set audio category: \(error)")
        }
    }

    public func activatePlaybackSession() {
        configureAudioSession()
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSessionManager: Failed to activate audio session: \(error)")
        }
    }

    public func deactivatePlaybackSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioSessionManager: Failed to deactivate audio session: \(error)")
        }
    }

    public func updateNowPlaying(
        title: String,
        channel: String,
        duration: TimeInterval,
        currentTime: TimeInterval,
        isPlaying: Bool,
        thumbnailImage: UIImage? = nil
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: channel,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let img = thumbnailImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    public func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }

            switch type {
            case .began:
                // System interrupted playback (phone call, alarm)
                self?.onInterruption?(false)
            case .ended:
                // Interruption ended, check if we should resume
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    let shouldResume = options.contains(.shouldResume)
                    self?.onInterruption?(shouldResume)
                }
            @unknown default:
                break
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
