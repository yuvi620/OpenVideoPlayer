import SwiftUI
import WebKit

/// Weak proxy to break the strong retain cycle between WKUserContentController and its message handler
public final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    public init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

public struct YouTubeIFramePlayerView: UIViewRepresentable {
    public let videoID: String
    @Binding public var state: PlaybackState
    public let command: PlaybackCommand?
    public let onTimeUpdate: (TimeInterval, TimeInterval) -> Void

    public init(
        videoID: String,
        state: Binding<PlaybackState>,
        command: PlaybackCommand? = nil,
        onTimeUpdate: @escaping (TimeInterval, TimeInterval) -> Void
    ) {
        self.videoID = videoID
        self._state = state
        self.command = command
        self.onTimeUpdate = onTimeUpdate
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        let contentController = config.userContentController
        let weakHandler = WeakScriptMessageHandler(delegate: context.coordinator)
        contentController.add(weakHandler, name: "playerState")
        contentController.add(weakHandler, name: "timeUpdate")
        contentController.add(weakHandler, name: "playerError")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        loadHTML(in: webView)
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Handle video ID changes with validation
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            if isValidVideoID(videoID) {
                let js = "if (player && player.loadVideoById) { player.loadVideoById('\(videoID)'); }"
                uiView.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        // Handle external playback commands from coordinator
        if let cmd = command, cmd != context.coordinator.lastHandledCommand {
            context.coordinator.lastHandledCommand = cmd
            switch cmd {
            case .play:
                uiView.evaluateJavaScript("if (player && player.playVideo) { player.playVideo(); }", completionHandler: nil)
            case .pause:
                uiView.evaluateJavaScript("if (player && player.pauseVideo) { player.pauseVideo(); }", completionHandler: nil)
            case .seek(let seconds):
                uiView.evaluateJavaScript("if (player && player.seekTo) { player.seekTo(\(seconds), true); }", completionHandler: nil)
            case .stop:
                uiView.evaluateJavaScript("if (player && player.stopVideo) { player.stopVideo(); }", completionHandler: nil)
            }
        }
    }

    public static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        let contentController = uiView.configuration.userContentController
        contentController.removeScriptMessageHandler(forName: "playerState")
        contentController.removeScriptMessageHandler(forName: "timeUpdate")
        contentController.removeScriptMessageHandler(forName: "playerError")
        contentController.removeAllUserScripts()
        coordinator.webView = nil
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func isValidVideoID(_ id: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_-]{5,32}$"
        return id.range(of: pattern, options: .regularExpression) != nil
    }

    private func loadHTML(in webView: WKWebView) {
        guard isValidVideoID(videoID) else {
            DispatchQueue.main.async {
                self.state = .failed("Invalid video ID format")
            }
            return
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { background: #000; overflow: hidden; width: 100vw; height: 100vh; }
                #player { width: 100vw; height: 100vh; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script src="https://www.youtube.com/iframe_api"></script>
            <script>
                var player;
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoID)',
                        playerVars: {
                            'playsinline': 1,
                            'controls': 1,
                            'rel': 0,
                            'modestbranding': 1,
                            'fs': 0,
                            'enablejsapi': 1
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange,
                            'onError': onPlayerError
                        }
                    });
                }
                function onPlayerReady(e) {
                    window.webkit.messageHandlers.playerState.postMessage({ state: 'ready' });
                }
                function onPlayerStateChange(e) {
                    window.webkit.messageHandlers.playerState.postMessage({ state: e.data });
                }
                function onPlayerError(e) {
                    window.webkit.messageHandlers.playerError.postMessage({ errorCode: e.data });
                }
                setInterval(function() {
                    if (player && player.getCurrentTime && player.getDuration) {
                        var cur = player.getCurrentTime();
                        var dur = player.getDuration();
                        if (dur > 0) {
                            window.webkit.messageHandlers.timeUpdate.postMessage({ current: cur, duration: dur });
                        }
                    }
                }, 500);
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
    }

    public final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: YouTubeIFramePlayerView
        weak var webView: WKWebView?
        var currentVideoID: String
        var lastHandledCommand: PlaybackCommand?

        init(_ parent: YouTubeIFramePlayerView) {
            self.parent = parent
            self.currentVideoID = parent.videoID
        }

        // Strict Navigation Restriction: Allow only YouTube player host and sub-resources
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let allowedHosts = [
                "www.youtube-nocookie.com",
                "youtube-nocookie.com",
                "www.youtube.com",
                "youtube.com",
                "www.googlevideo.com"
            ]

            if url.scheme == "about" && url.absoluteString == "about:blank" {
                decisionHandler(.allow)
                return
            }

            if let host = url.host?.lowercased() {
                if allowedHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
                    decisionHandler(.allow)
                    return
                }
            }

            // Reject all external link hijacking from within player
            decisionHandler(.cancel)
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if message.name == "playerState", let body = message.body as? [String: Any] {
                    if let rawState = body["state"] as? Int {
                        switch rawState {
                        case 0: self.parent.state = .ended
                        case 1: self.parent.state = .playing(currentTime: 0, duration: 0)
                        case 2: self.parent.state = .paused(currentTime: 0, duration: 0)
                        case 3: self.parent.state = .buffering
                        default: break
                        }
                    }
                } else if message.name == "timeUpdate", let body = message.body as? [String: Any],
                          let cur = body["current"] as? Double,
                          let dur = body["duration"] as? Double {
                    self.parent.onTimeUpdate(cur, dur)
                } else if message.name == "playerError", let body = message.body as? [String: Any],
                          let code = body["errorCode"] as? Int {
                    let errMsg: String
                    switch code {
                    case 2: errMsg = "Invalid YouTube video ID parameter."
                    case 5: errMsg = "HTML5 player error."
                    case 100: errMsg = "Video not found or has been removed."
                    case 101, 150: errMsg = "Embedding restricted by creator on third-party clients."
                    default: errMsg = "Playback error code \(code)"
                    }
                    self.parent.state = .failed(errMsg)
                }
            }
        }
    }
}
