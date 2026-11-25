import Observation
import SwiftUI
import WebKit

/// Owns the web view for the TV screen and everything the native controls do to it.
///
/// Sections (all in this file, so they can share private helpers):
/// - Remote: button presses, decades, reload
/// - Page: web view load events and messages from the page scripts
/// - Guide: years and categories
/// - Size and app switching: re-centering after a resize, resuming after Notification Center
/// - Helpers: JavaScript calls, LED and banner
@MainActor
@Observable
final class TVController {
    private(set) var decade: Decade
    var isLoading = true
    var hasError = false

    // Site modes for the current page. The site forgets them on every page load.
    /// Immersive Mode (just the TV, page around it hidden).
    private(set) var isImmersive = false
    /// Shuffle Mode (random years on channel change).
    private(set) var isShuffle = false
    /// Playlist Mode (clips play start to end, then the next channel).
    private(set) var isPlaylist = false

    /// The app's own full screen (video stretched over the page, app bars hidden).
    /// Unlike the site modes, it stays on across decades.
    private(set) var isFullScreen = false
    /// The small floating remote over a full-screen or landscape picture.
    var overlayRemote = false

    // LED and banner.
    private(set) var ledText: String
    /// Briefly true after each press, to show the LED over a full-screen picture.
    private(set) var toastVisible = false
    /// The site's status line ("Tube glow effect is now enabled"), shown for a moment.
    private(set) var banner: String?
    /// Bumped on every decade change, so the screen replays its switch-on flash.
    private(set) var tuneCount = 0
    /// Set when MTV Rewind is picked on the dial: the screen hands over to that set.
    private(set) var requestedSet: Decade?

    // What's on, read from the page.
    private(set) var nowTitle = ""
    /// "MUSIC - CH 9946". The site only shows it for a moment, so the last one is kept.
    private(set) var channelLabel = ""
    private(set) var years: [GuideYear] = []
    private(set) var categories: [GuideCategory] = []

    @ObservationIgnored weak var webView: WKWebView?
    @ObservationIgnored private var ledReset: Task<Void, Never>?
    @ObservationIgnored private var bannerReset: Task<Void, Never>?
    @ObservationIgnored private var immersiveTask: Task<Void, Never>?
    @ObservationIgnored private var filterTask: Task<Void, Never>?
    @ObservationIgnored private var relayoutTask: Task<Void, Never>?
    /// Hides the "Immersive mode is now on" banner when the app turned it on by itself.
    @ObservationIgnored private var quietImmersiveStatus = false
    @ObservationIgnored private var isAway = false

    init(decade: Decade) {
        self.decade = decade
        self.ledText = "CH \(decade.id)"
    }

    /// "MUSIC" from "MUSIC - CH 9946".
    var nowCategory: String {
        let parts = channelLabel.components(separatedBy: " - ")
        return parts.count > 1 ? parts[0].trimmingCharacters(in: .whitespaces) : ""
    }

    /// "9946" from "MUSIC - CH 9946".
    var channelNumber: String? {
        guard let range = channelLabel.range(of: #"CH\s*(\d+)"#, options: .regularExpression) else { return nil }
        return channelLabel[range].filter(\.isNumber)
    }

    private var autoImmersive: Bool {
        UserDefaults.standard.object(forKey: "autoImmersive") as? Bool ?? true
    }
}

// MARK: - Remote

extension TVController {
    func press(_ key: RemoteKey, haptic: Bool = true) {
        if haptic { Haptics.click() }
        switch key {
        case .volumeUp, .volumeDown:
            // iOS ignores web video volume, so change the phone's media volume instead.
            let level = SystemVolume.shared.step(up: key == .volumeUp)
            flash(SystemVolume.meter(level))
        case .fullScreen:
            setFullScreen(!isFullScreen)
        case .playlist:
            setPlaylist(!isPlaylist)
        case .immersive:
            isImmersive.toggle()
            updateScrolling()
            sendKey(key)
        case .shuffle:
            isShuffle.toggle()
            sendKey(key)
        default:
            sendKey(key)
        }
    }

    func tune(to decade: Decade) {
        guard decade != self.decade else { return }
        Haptics.thunk()
        if decade.isMTV {
            requestedSet = decade
            return
        }
        self.decade = decade
        UserDefaults.standard.set(decade.id, forKey: "lastDecade")
        tuneCount += 1
        flash("CH \(decade.id)")
        webView?.load(URLRequest(url: decade.url))
    }

    func reload() {
        hasError = false
        isLoading = true
        if webView?.url == nil {
            webView?.load(URLRequest(url: decade.url))
        } else {
            webView?.reload()
        }
    }

    /// A tap on the picture shows or hides the floating remote (only drawn when the
    /// app's own remote is hidden: full screen or landscape).
    func screenTapped() {
        overlayRemote.toggle()
    }

    private func setFullScreen(_ on: Bool) {
        isFullScreen = on
        overlayRemote = false
        updateScrolling()
        run("window.__retroFull && window.__retroFull(\(on));")
        flash(on ? "FULL" : idleLED)
    }

    private func setPlaylist(_ on: Bool) {
        isPlaylist = on
        sendKey(.playlist)
        run("window.__retroPlaylist && window.__retroPlaylist(\(on));")
        guard on else { return }
        // Playlist Mode only applies from the next channel, so start one now.
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard let self, self.isPlaylist else { return }
            self.sendKey(.channelUp, flashing: false)
        }
    }

    /// The page only scrolls in its normal layout; in Focus or full screen, swipes change channels.
    private func updateScrolling() {
        webView?.scrollView.isScrollEnabled = !(isImmersive || isFullScreen)
    }
}

// MARK: - Page

extension TVController {
    func pageStarted() {
        isLoading = true
        hasError = false
        immersiveTask?.cancel()
    }

    /// A new page starts with the site's normal layout and none of its modes on.
    func pageCommitted() {
        isImmersive = false
        isShuffle = false
        isPlaylist = false
        updateScrolling()
        nowTitle = ""
        channelLabel = ""
        years = []
        categories = []
    }

    func pageFinished() {
        isLoading = false
        hasError = false
        if isFullScreen {
            run("window.__retroFull && window.__retroFull(true);")
        }
        guard autoImmersive else { return }
        immersiveTask?.cancel()
        immersiveTask = Task { [weak self] in
            // Give the site a moment to set up the TV before switching modes.
            try? await Task.sleep(for: .milliseconds(1200))
            guard let self, !Task.isCancelled, !self.isImmersive else { return }
            self.quietImmersiveStatus = true
            self.isImmersive = true
            self.updateScrolling()
            self.sendKey(.immersive, flashing: false)
        }
    }

    func pageFailed() {
        isLoading = false
        hasError = true
    }

    /// Messages from the page script (Scripts.pageState).
    func handlePage(_ body: [String: Any]) {
        switch body["type"] as? String {
        case "status":
            guard let text = body["text"] as? String, !text.isEmpty else { return }
            if quietImmersiveStatus && text.localizedCaseInsensitiveContains("immersive") {
                quietImmersiveStatus = false
                return
            }
            showBanner(text)
        case "state":
            applyState(body)
        default:
            break
        }
    }

    private func applyState(_ body: [String: Any]) {
        let title = body["title"] as? String ?? ""
        if title != nowTitle { nowTitle = title }

        let label = body["channel"] as? String ?? ""
        if !label.isEmpty && label != channelLabel {
            channelLabel = label
            if !toastVisible { ledText = idleLED }
        }

        let newYears: [GuideYear] = (body["years"] as? [[String: Any]] ?? []).compactMap { item in
            guard let index = (item["index"] as? NSNumber)?.intValue, let name = item["name"] as? String else { return nil }
            return GuideYear(index: index, name: name, selected: (item["selected"] as? NSNumber)?.boolValue ?? false)
        }
        if newYears != years { years = newYears }

        let newCategories: [GuideCategory] = (body["categories"] as? [[String: Any]] ?? []).compactMap { item in
            guard let code = item["code"] as? String, let name = item["name"] as? String else { return nil }
            return GuideCategory(
                code: code,
                name: name,
                count: (item["count"] as? NSNumber)?.intValue ?? 0,
                checked: (item["checked"] as? NSNumber)?.boolValue ?? false
            )
        }
        if newCategories != categories { categories = newCategories }
    }
}

// MARK: - Guide

extension TVController {
    func selectYear(_ year: GuideYear) {
        guard !year.selected else { return }
        Haptics.thunk()
        flash(year.name)
        run("window.__retroGuide && window.__retroGuide.year(\(year.index));")
    }

    func setCategory(_ code: String, on: Bool) {
        Haptics.tick()
        if let index = categories.firstIndex(where: { $0.code == code }) {
            categories[index].checked = on
        }
        let safeCode = code.filter(\.isLetter)
        run("window.__retroGuide && window.__retroGuide.category('\(safeCode)', \(on));")
        applyFiltersSoon()
    }

    func selectAllCategories(_ on: Bool) {
        Haptics.click()
        for index in categories.indices { categories[index].checked = on }
        run("window.__retroGuide && window.__retroGuide.\(on ? "all" : "none")();")
        if on { applyFiltersSoon() }
    }

    /// The site applies filter changes on the next channel change, so change channel
    /// once the switches settle (and only if something is still picked).
    private func applyFiltersSoon() {
        filterTask?.cancel()
        filterTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard let self, !Task.isCancelled, self.categories.contains(where: \.checked) else { return }
            self.sendKey(.channelUp, flashing: false)
        }
    }
}

// MARK: - Size and app switching

extension TVController {
    /// After the picture changes size (leaving full screen, turning the phone), scroll
    /// the page back to the top and tell the site its window resized so it re-centers
    /// the TV. Repeats as the resize animation settles.
    func relayout() {
        relayoutTask?.cancel()
        relayoutTask = Task { [weak self] in
            for delay in [150, 500, 600] {
                try? await Task.sleep(for: .milliseconds(delay))
                guard let self, !Task.isCancelled else { return }
                self.webView?.scrollView.setContentOffset(.zero, animated: false)
                self.run("window.scrollTo(0, 0); window.dispatchEvent(new Event('resize'));")
            }
        }
    }

    /// Notification Center, Control Center or the app switcher covered the app: iOS
    /// pauses the video (and the site shows static), so note whether it was playing.
    func appLeaving() {
        guard !isAway else { return }
        isAway = true
        run("window.__retroResume && window.__retroResume.mark();")
    }

    /// Back in the app: play the clip again if it was playing.
    func appReturned() {
        guard isAway else { return }
        isAway = false
        run("window.__retroResume && window.__retroResume.resume();")
    }
}

// MARK: - Helpers

extension TVController {
    /// What the LED shows when nothing was just pressed.
    private var idleLED: String {
        if let number = channelNumber { return "CH \(number)" }
        return "CH \(decade.id)"
    }

    private func run(_ script: String) {
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }

    /// Presses one of the site's keys (Scripts.keyBridge), showing it on the LED.
    private func sendKey(_ key: RemoteKey, flashing: Bool = true) {
        if flashing { flash(key.led) }
        let escaped = key.rawValue
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        run("window.__retroKey && window.__retroKey('\(escaped)');")
    }

    private func flash(_ text: String) {
        ledText = text
        withAnimation(.easeOut(duration: 0.15)) { toastVisible = true }
        ledReset?.cancel()
        ledReset = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1400))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.ledText = self.idleLED
                self.toastVisible = false
            }
        }
    }

    private func showBanner(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { banner = text }
        bannerReset?.cancel()
        bannerReset = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(2400))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { self.banner = nil }
        }
    }
}
