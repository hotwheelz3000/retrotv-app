import SwiftUI
import UIKit

/// The MTV Rewind set: the same TV screen as the decade sets (picture in a glowing
/// frame, now-playing strip, remote below; full-screen picture with a pop-up remote
/// in landscape or Full), playing wantmymtv.org.
struct MTVScreen: View {
    /// Switches to a decade set picked on the dial.
    let onSwitch: (Decade) -> Void

    @State private var player = PlayerController()
    @State private var sheet: AppSheet?
    @State private var isFullScreen = false
    @State private var overlayRemote = false
    @State private var hideRemote: Task<Void, Never>?
    @State private var flashText: String?
    @State private var flashTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let set = Decade.mtv

    private var isLandscape: Bool { verticalSizeClass == .compact }
    /// Landscape or full screen: just the picture, with floating controls.
    private var chromeHidden: Bool { isLandscape || isFullScreen }

    private var ledText: String {
        if let flashText { return flashText }
        let channel = player.now.channelName.trimmingCharacters(in: .whitespaces)
        return channel.isEmpty ? "CH MTV" : channel.uppercased()
    }

    var body: some View {
        GeometryReader { geo in
            screen(width: geo.size.width)
        }
        .ignoresSafeArea(.all, edges: chromeHidden ? .all : [])
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: chromeHidden)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(item: $sheet) { which in
            switch which {
            case .channels: ChannelsSheet(player: player)
            case .timeMachine: TimeMachineSheet(player: player)
            case .search: SearchSheet(player: player)
            case .saved: SavedSheet(player: player)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            UserDefaults.standard.set(set.id, forKey: "lastDecade")
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: chromeHidden) {
            overlayRemote = false
            player.relayout()
        }
        .onChange(of: overlayRemote) {
            if overlayRemote { scheduleHide() }
        }
    }

    /// One layout for every mode, so turning the phone or going full screen never
    /// reloads the player: the bars and remote just come and go, and the picture
    /// goes from 16:9 under the top bar to the whole screen.
    private func screen(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()
            VolumeViewHost()
                .frame(width: 1, height: 1)

            VStack(spacing: chromeHidden ? 0 : 12) {
                if !chromeHidden {
                    topBar
                    Spacer(minLength: 0)
                }
                picture
                    .frame(maxWidth: .infinity, maxHeight: chromeHidden ? .infinity : nil)
                    .frame(height: chromeHidden ? nil : (width - 20) * 9 / 16)
                    .clipShape(RoundedRectangle(cornerRadius: chromeHidden ? 0 : 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: chromeHidden ? 0 : 20, style: .continuous)
                            .strokeBorder(set.glow.opacity(chromeHidden ? 0 : 0.35), lineWidth: 1.5)
                    )
                    .shadow(color: set.glow.opacity(chromeHidden ? 0 : 0.3), radius: 24)
                    .padding(.horizontal, chromeHidden ? 0 : 10)
                if !chromeHidden {
                    MTVNowPlayingStrip(player: player)
                        .padding(.horizontal, 14)
                    remote(compact: false)
                        .padding(.horizontal, 8)
                    Spacer(minLength: 4)
                }
            }
            .ignoresSafeArea(.all, edges: chromeHidden ? .all : [])

            if chromeHidden {
                floatingControls
            }
        }
    }

    // MARK: Portrait

    private var topBar: some View {
        HStack(spacing: 12) {
            CircleIconButton(symbol: "chevron.down", label: "Back to all TVs") {
                Haptics.click()
                dismiss()
            }
            VStack(alignment: .leading, spacing: 1) {
                Wordmark(size: 15, alignment: .leading)
                Text(set.tagline)
                    .font(Theme.label(12, weight: .semibold))
                    .foregroundStyle(Theme.dim)
            }
            Spacer()
            if !player.loaded && !player.offline {
                ProgressView().tint(Theme.amber)
            }
            CircleIconButton(symbol: "arrow.clockwise", label: "Reload") {
                Haptics.click()
                player.retry()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func remote(compact: Bool) -> some View {
        MTVRemote(
            player: player,
            compact: compact,
            ledText: ledText,
            isFullScreen: isFullScreen,
            onFullScreen: toggleFullScreen,
            onVolume: { up in
                let level = SystemVolume.shared.step(up: up)
                flash(SystemVolume.meter(level))
            },
            onSheet: { sheet = $0 },
            onSwitch: onSwitch
        )
    }

    // MARK: Full screen and landscape

    /// Small floating buttons over the picture. Tapping the picture (or the remote
    /// button) brings up the full remote: from the right in landscape, from the
    /// bottom in portrait.
    private var floatingControls: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 10) {
                CircleIconButton(symbol: "chevron.down", label: "Back to all TVs") {
                    Haptics.click()
                    dismiss()
                }
                Spacer()
                if isFullScreen {
                    CircleIconButton(symbol: "arrow.down.right.and.arrow.up.left", label: "Exit full screen") {
                        toggleFullScreen()
                    }
                }
                CircleIconButton(symbol: overlayRemote ? "xmark" : "av.remote", label: "Remote") {
                    Haptics.click()
                    overlayRemote.toggle()
                }
            }
            .padding(14)
            .opacity(overlayRemote ? 1 : 0.5)

            if flashText != nil && !overlayRemote {
                LEDDisplay(text: ledText)
                    .frame(width: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if overlayRemote {
                overlayRemoteView
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: overlayRemote)
    }

    @ViewBuilder
    private var overlayRemoteView: some View {
        let remote = remote(compact: true)
            .simultaneousGesture(TapGesture().onEnded { scheduleHide() })
        if isLandscape {
            HStack {
                Spacer()
                remote
                    .frame(width: 360)
                    .padding(.trailing, 12)
                    .padding(.vertical, 8)
            }
            .frame(maxHeight: .infinity)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            VStack {
                Spacer()
                remote
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func toggleFullScreen() {
        Haptics.click()
        isFullScreen.toggle()
        overlayRemote = false
        flash(isFullScreen ? "FULL" : nil)
    }

    private func scheduleHide() {
        hideRemote?.cancel()
        hideRemote = Task {
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            overlayRemote = false
        }
    }

    /// Shows a message on the LED for a moment ("VOL ▮▮▮▯▯", "FULL").
    private func flash(_ text: String?) {
        flashTask?.cancel()
        flashText = text
        guard text != nil else { return }
        flashTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            flashText = nil
        }
    }

    // MARK: Picture

    private var picture: some View {
        ZStack {
            Color.black
            MTVWebView(state: player)
                .opacity(player.offline ? 0 : 1)

            // Takes the touches, so YouTube's own overlay never shows. Tap: play or
            // pause (or the remote, when it's hidden). Double-tap: Full. Swipe: next or previous.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    guard !isLandscape else { return }
                    toggleFullScreen()
                }
                .onTapGesture {
                    if chromeHidden {
                        Haptics.click()
                        overlayRemote.toggle()
                    } else {
                        player.playPause()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 30).onEnded { value in
                        let dx = value.translation.width
                        guard abs(dx) > abs(value.translation.height) else { return }
                        if dx < 0 { player.next() } else { player.previous() }
                    }
                )
                .accessibilityElement()
                .accessibilityLabel("Video")
                .accessibilityHint("Double-tap to play or pause. Swipe for next or previous.")
                .accessibilityAddTraits(.startsMediaSession)

            if !player.loaded && !player.offline {
                TuningOverlay(decade: set)
                    .transition(.opacity)
            }
            if player.offline {
                NoSignalView { player.retry() }
                    .transition(.opacity)
            }
            PowerOnFlash()

            if let toast = player.toast {
                VStack {
                    Text(toast)
                        .font(Theme.label(14, weight: .bold))
                        .foregroundStyle(Theme.cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                        )
                        .overlay(Capsule(style: .continuous).strokeBorder(Theme.amber.opacity(0.5), lineWidth: 1))
                        .shadow(color: .black.opacity(0.5), radius: 10)
                        .padding(.top, chromeHidden ? 64 : 14)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
                .id(toast)
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.onChange(of: proxy.size) { player.relayout() }
            }
        )
        .animation(.easeOut(duration: 0.35), value: player.loaded)
        .animation(.easeOut(duration: 0.25), value: player.offline)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: player.toast)
    }
}

/// What's on under the picture, like the decade sets' strip, plus a heart to save it.
struct MTVNowPlayingStrip: View {
    let player: PlayerController

    private var title: String {
        let now = player.now
        if now.title.isEmpty { return now.artist }
        return now.artist.isEmpty ? now.title : "\(now.artist) – \(now.title)"
    }

    var body: some View {
        HStack(spacing: 10) {
            if !player.now.channelName.isEmpty {
                CategoryChip(text: player.now.channelName.uppercased(), color: Decade.mtv.glow)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Decade.mtv.glow)
            }
            Marquee(text: title.isEmpty ? "Tuning in…" : title)
                .frame(height: 20)
            Button {
                player.toggleSave()
            } label: {
                Image(systemName: player.now.saved ? "heart.fill" : "heart")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(player.now.saved ? Theme.red : Theme.dim)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.85))
            .disabled(player.now.videoId.isEmpty)
            .accessibilityLabel(player.now.saved ? "Remove from saved" : "Save this video")
        }
        .padding(.leading, 14)
        .padding(.trailing, 2)
        .frame(height: 36)
        .background(Capsule(style: .continuous).fill(Theme.panel))
        .overlay(Capsule(style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

/// MTV Rewind's remote, built from the same parts as the decade sets' remote.
/// CH changes the video; the dial switches to a decade set.
struct MTVRemote: View {
    let player: PlayerController
    var compact = false
    let ledText: String
    let isFullScreen: Bool
    let onFullScreen: () -> Void
    let onVolume: (Bool) -> Void
    let onSheet: (AppSheet) -> Void
    let onSwitch: (Decade) -> Void

    var body: some View {
        VStack(spacing: compact ? 12 : 16) {
            HStack(alignment: .center, spacing: 14) {
                RoundRemoteButton(
                    symbol: player.now.playing ? "pause.fill" : "play.fill",
                    tint: Theme.red,
                    label: player.now.playing ? "Pause" : "Play"
                ) {
                    player.playPause()
                }
                Button {
                    Haptics.click()
                    onSheet(.channels)
                } label: {
                    LEDDisplay(text: ledText)
                }
                .buttonStyle(PressableStyle(scale: 0.97))
                .accessibilityLabel("Open channels")
                RoundRemoteButton(symbol: "list.bullet.rectangle", tint: Theme.panelHigh, label: "Channels") {
                    Haptics.click()
                    onSheet(.channels)
                }
            }

            HStack(alignment: .center, spacing: 14) {
                Rocker(title: "VOL", upSymbol: "plus", downSymbol: "minus") {
                    Haptics.click()
                    onVolume(true)
                } down: {
                    Haptics.click()
                    onVolume(false)
                }
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        PillButton(
                            symbol: isFullScreen
                                ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                            title: isFullScreen ? "Exit full" : "Full",
                            highlighted: isFullScreen,
                            action: onFullScreen
                        )
                        PillButton(symbol: "calendar", title: "Years") {
                            Haptics.click()
                            onSheet(.timeMachine)
                        }
                    }
                    HStack(spacing: 10) {
                        PillButton(symbol: "magnifyingglass", title: "Search") {
                            Haptics.click()
                            onSheet(.search)
                        }
                        PillButton(symbol: "heart", title: "Saved") {
                            Haptics.click()
                            onSheet(.saved)
                        }
                    }
                }
                Rocker(title: "CH", upSymbol: "chevron.up", downSymbol: "chevron.down") {
                    player.next()
                } down: {
                    player.previous()
                }
            }

            DecadeDial(selected: Decade.mtv) { picked in
                guard !picked.isMTV else { return }
                Haptics.thunk()
                onSwitch(picked)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, compact ? 14 : 18)
        .padding(.bottom, compact ? 14 : 8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.panelHigh, Theme.panel],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: -4)
        )
    }
}
