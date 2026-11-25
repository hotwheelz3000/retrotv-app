import SwiftUI
import UIKit
import WebKit

/// A web view that reports when its size changes (full screen, rotation), so the
/// page can be re-laid out for the new size.
final class TVWebView: WKWebView {
    var onResize: (() -> Void)?
    private var lastSize: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastSize, bounds.width > 0, bounds.height > 0 else { return }
        let first = lastSize == .zero
        lastSize = bounds.size
        if !first { onResize?() }
    }
}

/// The MyRetroTVs page, shown inside the app's TV frame.
struct RetroWebView: UIViewRepresentable {
    let controller: TVController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.websiteDataStore = .default()
        // Identify as Safari: the site's YouTube clips can show only static in
        // embedded browsers it doesn't recognise.
        configuration.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        let scripts = configuration.userContentController
        scripts.addUserScript(
            WKUserScript(source: Scripts.keyBridge, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        scripts.addUserScript(
            WKUserScript(source: Scripts.appPolish, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        scripts.addUserScript(
            WKUserScript(source: Scripts.fullScreen, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        scripts.addUserScript(
            WKUserScript(source: Scripts.pageState, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        scripts.addUserScript(
            WKUserScript(source: Scripts.playerWatch, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        scripts.add(context.coordinator, name: "retro")

        let webView = TVWebView(frame: .zero, configuration: configuration)
        webView.onResize = { [weak controller] in controller?.relayout() }
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        context.coordinator.addSwipes(to: webView)

        controller.webView = webView
        webView.load(URLRequest(url: controller.decade.url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate,
        WKScriptMessageHandler {
        let controller: TVController

        init(controller: TVController) {
            self.controller = controller
        }

        // MARK: Swipes: up/down changes channel, left/right changes decade.

        func addSwipes(to webView: WKWebView) {
            let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
            for direction in directions {
                let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
                swipe.direction = direction
                swipe.delegate = self
                webView.addGestureRecognizer(swipe)
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            tap.delegate = self
            tap.cancelsTouchesInView = false
            webView.addGestureRecognizer(tap)
        }

        @objc private func tapped() {
            controller.screenTapped()
        }

        @objc private func swiped(_ swipe: UISwipeGestureRecognizer) {
            switch swipe.direction {
            case .up:
                controller.press(.channelUp)
            case .down:
                controller.press(.channelDown)
            case .left:
                if let next = controller.decade.next { controller.tune(to: next) }
            case .right:
                if let previous = controller.decade.previous { controller.tune(to: previous) }
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let swipe = gestureRecognizer as? UISwipeGestureRecognizer else { return true }
            // In full screen the video fills the page, so up/down always change channels.
            if controller.isFullScreen { return true }
            // Up/down only change channels when the page itself can't scroll
            // (Immersive Mode); otherwise they scroll the page as usual.
            if swipe.direction == .up || swipe.direction == .down {
                return controller.isImmersive
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        // MARK: Page messages

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: Any] else { return }
            controller.handlePage(body)
        }

        // MARK: Navigation

        /// The seven TV sets (and the main site) stay in the app; everything else opens in Safari.
        private func isInternal(_ url: URL) -> Bool {
            guard let host = url.host?.lowercased() else { return true }
            return host == "myretrotvs.com" || host.hasSuffix(".myretrotvs.com")
        }

        private func isWebScheme(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased() else { return true }
            return ["http", "https", "about", "blob", "data", "javascript"].contains(scheme)
        }

        private func openExternally(_ url: URL) {
            UIApplication.shared.open(url)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else { return .allow }
            if !isWebScheme(url) {
                openExternally(url)
                return .cancel
            }
            // YouTube players and other frames inside the page load normally.
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            guard isMainFrame else { return .allow }
            if !isInternal(url) {
                openExternally(url)
                return .cancel
            }
            // Keep the app's decade picker in step when the site's own links switch sets.
            if let host = url.host?.lowercased(),
               let decade = Decade.all.first(where: { host.hasPrefix("\($0.id).") }),
               decade != controller.decade,
               navigationAction.navigationType == .linkActivated {
                controller.tune(to: decade)
                return .cancel
            }
            return .allow
        }

        /// New windows (the YouTube button, the donation link) open in Safari or the YouTube app.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                if isInternal(url) && isWebScheme(url) {
                    webView.load(navigationAction.request)
                } else {
                    openExternally(url)
                }
            }
            return nil
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            controller.pageStarted()
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            controller.pageCommitted()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            controller.pageFinished()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        private func handle(_ error: Error) {
            let error = error as NSError
            // A load replaced by another one (changing decades quickly) or stopped by
            // the app's own link handling isn't a failure.
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled { return }
            if error.domain == "WebKitErrorDomain" && error.code == 102 { return }
            controller.pageFailed()
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }
    }
}
