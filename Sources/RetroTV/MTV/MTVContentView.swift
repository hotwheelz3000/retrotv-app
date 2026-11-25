import SwiftUI
import UIKit

enum AppSheet: String, Identifiable {
    case channels, timeMachine, search, saved, about
    var id: String { rawValue }
}

/// Spacing, corner and size values used everywhere, on an 8-point grid.
enum Metrics {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    /// Side margin for the main screen.
    static let gutter: CGFloat = 16
    /// The widest the main column gets (iPad, large text).
    static let maxWidth: CGFloat = 560
    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 16
    static let screenRadius: CGFloat = 18
    static let minTap: CGFloat = 44
}

struct MTVContentView: View {
    /// Back to the Retro TV living room.
    var onClose: () -> Void = {}

    @State private var player = PlayerController()
    @State private var sheet: AppSheet?
    @State private var fullScreen = false
    @State private var showsFloatingRemote = false
    @State private var hideRemoteTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            let full = landscape || fullScreen
            let columnWidth = min(geo.size.width, Metrics.maxWidth)
            let screenWidth = columnWidth - Metrics.gutter * 2
            ZStack {
                Color.clear.onChange(of: geo.size) { player.relayout() }
                MTVTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if !full {
                        header
                            .padding(.horizontal, Metrics.gutter)
                            .padding(.top, Metrics.xs)
                            .padding(.bottom, Metrics.md)
                            .frame(maxWidth: Metrics.maxWidth)
                    }

                    screen(full: full)
                        .frame(
                            width: full ? nil : screenWidth,
                            height: full ? nil : screenWidth * 9 / 16
                        )
                        .frame(maxWidth: full ? .infinity : nil, maxHeight: full ? .infinity : nil)
                        .clipShape(RoundedRectangle(cornerRadius: full ? 0 : Metrics.screenRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: full ? 0 : Metrics.screenRadius, style: .continuous)
                                .strokeBorder(MTVTheme.royal.opacity(full ? 0 : 0.55), lineWidth: 1)
                                .allowsHitTesting(false)
                        )

                    if !full {
                        ScrollView {
                            VStack(spacing: Metrics.lg) {
                                NowPlayingCard(player: player) { sheet = .channels }
                                Remote(player: player, sheet: $sheet) {
                                    withAnimation(.snappy) { fullScreen = true }
                                }
                            }
                            .padding(.horizontal, Metrics.gutter)
                            .padding(.top, Metrics.lg)
                            .padding(.bottom, Metrics.xl)
                            .frame(maxWidth: Metrics.maxWidth)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: full ? .all : [])

                if player.offline {
                    OfflineView { player.retry() }
                        .transition(.opacity)
                } else if !player.loaded {
                    LoadingView()
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .onChange(of: fullScreen) { player.relayout() }
        .statusBarHidden(fullScreen)
        .persistentSystemOverlays(fullScreen ? .hidden : .automatic)
        .animation(.easeInOut(duration: 0.45), value: player.loaded)
        .animation(.easeOut(duration: 0.25), value: player.offline)
        .sheet(item: $sheet) { which in
            switch which {
            case .channels: ChannelsSheet(player: player)
            case .timeMachine: TimeMachineSheet(player: player)
            case .search: SearchSheet(player: player)
            case .saved: SavedSheet(player: player)
            case .about: MTVAboutView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Metrics.md) {
            Button {
                MTVHaptics.click()
                onClose()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MTVTheme.dim)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(MTVTheme.navy))
                    .overlay(Circle().strokeBorder(MTVTheme.royal.opacity(0.6), lineWidth: 1))
                    .frame(width: Metrics.minTap, height: Metrics.minTap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MTVPressableStyle())
            .accessibilityLabel("Back to all TVs")
            Wordmark(size: 24, alignment: .leading)
            Spacer(minLength: 0)
            Button {
                MTVHaptics.click()
                sheet = .about
            } label: {
                Image(systemName: "info")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MTVTheme.dim)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(MTVTheme.navy))
                    .overlay(Circle().strokeBorder(MTVTheme.royal.opacity(0.6), lineWidth: 1))
                    .frame(width: Metrics.minTap, height: Metrics.minTap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MTVPressableStyle())
            .accessibilityLabel("About MTV Rewind")
        }
    }

    /// The video, with swipe and tap on top (the site's own page stays hidden underneath).
    private func screen(full: Bool) -> some View {
        ZStack {
            MTVWebView(state: player)
            MTVScanlines(spacing: 3, opacity: 0.1)

            // Takes the touches, so YouTube's own overlay never shows.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    guard !full || fullScreen else { return }
                    MTVHaptics.click()
                    withAnimation(.snappy) { fullScreen.toggle() }
                }
                .onTapGesture {
                    if full { flashRemote() } else { player.playPause() }
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

            if let toast = player.toast {
                Text(toast)
                    .font(MTVTheme.label(13, weight: .bold))
                    .foregroundStyle(MTVTheme.text)
                    .padding(.horizontal, Metrics.md)
                    .padding(.vertical, Metrics.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, full ? Metrics.lg : Metrics.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .allowsHitTesting(false)
            }

            if full && showsFloatingRemote {
                FloatingRemote(
                    player: player, canExit: fullScreen,
                    onExit: { withAnimation(.snappy) { fullScreen = false; showsFloatingRemote = false } },
                    onClose: onClose
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, Metrics.xl)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
        .background(Color.black)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: player.toast)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showsFloatingRemote)
    }

    private func flashRemote() {
        showsFloatingRemote.toggle()
        hideRemoteTask?.cancel()
        guard showsFloatingRemote else { return }
        hideRemoteTask = Task {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { showsFloatingRemote = false }
        }
    }
}

// MARK: Now playing

private struct NowPlayingCard: View {
    let player: PlayerController
    let onChannel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sm) {
            Button {
                MTVHaptics.click()
                onChannel()
            } label: {
                HStack(spacing: Metrics.sm) {
                    Circle()
                        .fill(player.now.playing ? MTVTheme.red : MTVTheme.dim)
                        .frame(width: 6, height: 6)
                        .shadow(color: MTVTheme.red, radius: player.now.playing ? 3 : 0)
                    Text(channelLabel)
                        .font(MTVTheme.led(11))
                        .tracking(0.5)
                        .foregroundStyle(MTVTheme.yellow)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(MTVTheme.dim)
                }
                .padding(.horizontal, Metrics.md - 4)
                .frame(minHeight: 30)
                .background(Capsule().fill(MTVTheme.navy).overlay(Capsule().strokeBorder(MTVTheme.deep, lineWidth: 1)))
                .frame(minHeight: Metrics.minTap)
                .contentShape(Rectangle())
            }
            .buttonStyle(MTVPressableStyle())
            .accessibilityLabel("Channel: \(channelName)")
            .accessibilityHint("Opens the channel list")

            Group {
                if hasSong {
                    VStack(alignment: .leading, spacing: Metrics.xs) {
                        Text(player.now.title)
                            .font(MTVTheme.display(26))
                            .foregroundStyle(MTVTheme.text)
                            .outlined(1, drop: 2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(player.now.artist.isEmpty ? " " : player.now.artist)
                            .font(MTVTheme.label(17, weight: .bold))
                            .foregroundStyle(MTVTheme.salmon)
                            .lineLimit(1)
                    }
                    .id(player.now.videoId)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 6)),
                        removal: .opacity
                    ))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Now playing: \(player.now.title), by \(player.now.artist)")
                } else {
                    SkeletonLines()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: player.now.videoId)
        .animation(.easeInOut(duration: 0.3), value: hasSong)
    }

    private var hasSong: Bool { !player.now.title.isEmpty }

    private var channelName: String {
        player.now.channelName.isEmpty ? "MTV Rewind" : player.now.channelName
    }

    private var channelLabel: String {
        "\(player.now.icon) \(channelName.uppercased())"
    }
}

/// Soft placeholder bars while the first song loads.
private struct SkeletonLines: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sm + 2) {
            Capsule().frame(width: 230, height: 22)
            Capsule().frame(width: 140, height: 14)
        }
        .foregroundStyle(MTVTheme.navy)
        .opacity(pulse ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading song")
    }
}

// MARK: Remote

private struct Remote: View {
    let player: PlayerController
    @Binding var sheet: AppSheet?
    let onFull: () -> Void

    var body: some View {
        VStack(spacing: Metrics.lg) {
            HStack(spacing: Metrics.lg) {
                RoundButton(symbol: "backward.fill", size: 60, style: .light, label: "Previous") {
                    player.previous()
                }
                RoundButton(
                    symbol: player.now.playing ? "pause.fill" : "play.fill",
                    size: 80, style: .enter, label: player.now.playing ? "Pause" : "Play"
                ) {
                    player.playPause()
                }
                RoundButton(symbol: "forward.fill", size: 60, style: .light, label: "Next") {
                    player.next()
                }
            }
            .padding(.top, Metrics.xs)

            HStack(spacing: Metrics.sm) {
                MTVPillButton(
                    symbol: player.now.saved ? "heart.fill" : "heart",
                    title: player.now.saved ? "Saved" : "Save",
                    highlighted: player.now.saved
                ) { player.toggleSave() }
                    .accessibilityLabel(player.now.saved ? "Remove from saved" : "Save this video")
                if let url = player.shareURL {
                    ShareLink(item: url, subject: Text(shareText), message: Text(shareText)) {
                        PillLabel(symbol: "square.and.arrow.up", title: "Share")
                    }
                    .buttonStyle(MTVPressableStyle(scale: 0.95))
                    .simultaneousGesture(TapGesture().onEnded { MTVHaptics.click() })
                    .accessibilityLabel("Share this video")
                } else {
                    MTVPillButton(symbol: "square.and.arrow.up", title: "Share") {}
                        .disabled(true)
                        .opacity(0.5)
                }
                MTVPillButton(symbol: "exclamationmark.arrow.triangle.2.circlepath", title: "Skip") {
                    player.skip()
                }
                .accessibilityLabel("Skip a video that won't play")
                MTVPillButton(symbol: "arrow.up.left.and.arrow.down.right", title: "Full") {
                    MTVHaptics.click()
                    onFull()
                }
                .accessibilityLabel("Full screen")
            }

            Rectangle()
                .fill(MTVTheme.royal.opacity(0.35))
                .frame(height: 1)
                .accessibilityHidden(true)

            Grid(horizontalSpacing: Metrics.sm, verticalSpacing: Metrics.sm) {
                GridRow {
                    BigTile(symbol: "tv", title: "Channels", tint: MTVTheme.sky) { open(.channels) }
                    BigTile(symbol: "clock.arrow.circlepath", title: "Time Machine", tint: MTVTheme.yellow) {
                        open(.timeMachine)
                    }
                }
                GridRow {
                    BigTile(symbol: "magnifyingglass", title: "Search", tint: MTVTheme.pink) { open(.search) }
                    BigTile(symbol: "heart.text.square", title: "Saved", tint: MTVTheme.salmon) { open(.saved) }
                }
            }
        }
        .padding(Metrics.md + 4)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(LinearGradient(colors: [MTVTheme.deep, MTVTheme.navy], startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                        .strokeBorder(MTVTheme.royal, lineWidth: 1.5)
                )
        )
    }

    private var shareText: String {
        [player.now.artist, player.now.title].filter { !$0.isEmpty }.joined(separator: " – ")
    }

    private func open(_ which: AppSheet) {
        MTVHaptics.click()
        sheet = which
    }
}

/// Prev / play / next over the picture in full screen; tap the picture to show it.
private struct FloatingRemote: View {
    let player: PlayerController
    let canExit: Bool
    let onExit: () -> Void
    /// Back to the living room. Shown in landscape, where the header is hidden.
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: Metrics.md + 4) {
            if !canExit {
                RoundButton(symbol: "chevron.down", size: 50, style: .light, label: "Back to all TVs") {
                    MTVHaptics.click()
                    onClose()
                }
            }
            RoundButton(symbol: "backward.fill", size: 50, style: .light, label: "Previous") {
                player.previous()
            }
            RoundButton(
                symbol: player.now.playing ? "pause.fill" : "play.fill",
                size: 64, style: .enter, label: player.now.playing ? "Pause" : "Play"
            ) { player.playPause() }
            RoundButton(symbol: "forward.fill", size: 50, style: .light, label: "Next") {
                player.next()
            }
            if canExit {
                RoundButton(
                    symbol: "arrow.down.right.and.arrow.up.left", size: 50, style: .light,
                    label: "Exit full screen"
                ) {
                    MTVHaptics.click()
                    onExit()
                }
            }
        }
        .padding(.horizontal, Metrics.md + 4)
        .padding(.vertical, Metrics.md)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)
    }
}

struct RoundButton: View {
    enum Style { case enter, light }

    let symbol: String
    var size: CGFloat = 56
    var style: Style = .light
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.34, weight: .heavy))
                .foregroundStyle(style == .enter ? MTVTheme.text : MTVTheme.ink)
                .contentTransition(.symbolEffect(.replace))
                .offset(x: symbol == "play.fill" ? size * 0.03 : 0)
                .frame(width: size, height: size)
                .background(face)
                .padding(.bottom, 4)
                .frame(minWidth: Metrics.minTap, minHeight: Metrics.minTap)
                .contentShape(Circle())
        }
        .buttonStyle(MTVPressableStyle(scale: 0.92))
        .accessibilityLabel(label)
    }

    /// Enter-button style (pink to blue, yellow ring) or light blue, both with a dark
    /// outline and a hard drop shadow.
    @ViewBuilder private var face: some View {
        switch style {
        case .enter:
            Circle()
                .fill(MTVTheme.enter)
                .overlay(Circle().strokeBorder(MTVTheme.yellow, lineWidth: size * 0.07))
                .overlay(Circle().strokeBorder(MTVTheme.ink, lineWidth: 2))
                .background(Circle().fill(MTVTheme.purple).offset(y: 4))
                .background(Circle().strokeBorder(MTVTheme.ink, lineWidth: 2).offset(y: 4))
        case .light:
            Circle()
                .fill(MTVTheme.lightBlue)
                .overlay(Circle().strokeBorder(MTVTheme.ink, lineWidth: 2))
                .background(Circle().fill(MTVTheme.ink).offset(y: 3))
        }
    }
}

struct PillLabel: View {
    let symbol: String
    let title: String
    var highlighted = false

    var body: some View {
        VStack(spacing: Metrics.xs + 1) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(height: 20)
                .contentTransition(.symbolEffect(.replace))
            Text(title)
                .font(MTVTheme.label(11, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(highlighted ? MTVTheme.ink : MTVTheme.text)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: Metrics.controlRadius - 2, style: .continuous)
                .fill(highlighted ? MTVTheme.salmon : MTVTheme.navy)
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.controlRadius - 2, style: .continuous)
                        .strokeBorder(highlighted ? MTVTheme.ink : MTVTheme.royal.opacity(0.6), lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: Metrics.controlRadius - 2, style: .continuous))
    }
}

struct MTVPillButton: View {
    let symbol: String
    let title: String
    var highlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PillLabel(symbol: symbol, title: title, highlighted: highlighted)
        }
        .buttonStyle(MTVPressableStyle(scale: 0.95))
    }
}

private struct BigTile: View {
    let symbol: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.sm + 4) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24)
                Text(title)
                    .font(MTVTheme.label(15, weight: .bold))
                    .foregroundStyle(MTVTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MTVTheme.dim)
            }
            .padding(.horizontal, Metrics.md - 2)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(MTVTheme.navy)
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .strokeBorder(MTVTheme.royal.opacity(0.6), lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous))
        }
        .buttonStyle(MTVPressableStyle(scale: 0.97))
        .accessibilityHint("Opens \(title)")
    }
}

// MARK: Loading and offline

/// The icon on black with a spinner, until the player loads.
private struct LoadingView: View {
    var body: some View {
        ZStack {
            MTVTheme.background.ignoresSafeArea()
            VStack(spacing: Metrics.lg) {
                AppIconImage(size: 112)
                    .shadow(color: MTVTheme.royal.opacity(0.35), radius: 24, y: 8)
                Wordmark(size: 26)
                ProgressView()
                    .tint(MTVTheme.pink)
                    .controlSize(.regular)
                    .padding(.top, Metrics.sm)
            }
            .offset(y: -Metrics.lg)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading MTV Rewind")
    }
}

private struct OfflineView: View {
    let retry: () -> Void

    var body: some View {
        ZStack {
            MTVTheme.background.ignoresSafeArea()
            VStack(spacing: Metrics.md) {
                AppIconImage(size: 96)
                    .opacity(0.6)
                    .padding(.bottom, Metrics.sm)
                Text(L10n.offlineTitle)
                    .font(MTVTheme.display(22))
                    .foregroundStyle(MTVTheme.text)
                Text(L10n.offlineMessage)
                    .font(MTVTheme.label(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MTVTheme.dim)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: retry) {
                    Text(L10n.retry)
                        .font(MTVTheme.label(17, weight: .bold))
                        .frame(minWidth: 140, minHeight: 50)
                        .background(MTVTheme.enter, in: Capsule())
                        .overlay(Capsule().strokeBorder(MTVTheme.yellow, lineWidth: 3))
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(MTVPressableStyle())
                .padding(.top, Metrics.sm)
            }
            .frame(maxWidth: 360)
            .padding(Metrics.xl)
        }
    }
}

struct AppIconImage: View {
    var size: CGFloat = 120

    private static let image: UIImage? = Bundle.module
        .path(forResource: "LaunchIcon", ofType: "png")
        .flatMap { UIImage(contentsOfFile: $0) }

    var body: some View {
        if let image = Self.image {
            Image(uiImage: image)
                .resizable()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .accessibilityHidden(true)
        }
    }
}
