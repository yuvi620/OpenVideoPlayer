import Foundation
import SwiftUI
import Combine

public enum PlaybackCommand: Equatable, Sendable {
    case play
    case pause
    case seek(TimeInterval)
    case stop
}

public protocol PlaybackCoordinatorProtocol: AnyObject, ObservableObject {
    var state: PlaybackState { get }
    var currentItem: VideoItem? { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var playbackCommand: PlaybackCommand? { get }

    func load(item: VideoItem)
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
    func stop()
    func updateState(_ newState: PlaybackState)
}

public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing(currentTime: TimeInterval, duration: TimeInterval)
    case paused(currentTime: TimeInterval, duration: TimeInterval)
    case buffering
    case ended
    case failed(String)

    public var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    public var isEnded: Bool {
        if case .ended = self { return true }
        return false
    }
}
