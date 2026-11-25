import SwiftUI
import UIKit

/// One decade's TV: the site's picture in a native frame, with the remote below
/// (portrait) or a full-screen picture with a pop-up remote (landscape).
struct TVScreen: View {
    @State private var controller: TVController
    @State private var showEffects = false
    @State private var showGuide = false
    @State private var hideRemote: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    /// Switches to another set that isn't a decade (MTV Rewind).
    private let onSwitch: (Decade) -> Void

    init(decade: Decade, onSwitch: @escaping (Decade) -> Void = { _ in }) {
        _controller = State(initialValue: TVController(decade: decade))
        self.onSwitch = onSwitch
    }

    private var isLandscape: Bool { verticalSizeClass == .compact }
    /// Landscape or full screen: just the picture, with floating controls.
    private var chromeHidden: Bool { isLandscape || controller.isFullScreen }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()
            VolumeViewHost()
                .frame(width: 1, height: 1)

            // One layout for every mode, so turning the phone or going full screen
            // never reloads the web view: the bars and remote just come and go.
            VStack(spacing: chromeHidden ? 0 : 12) {
                if !chromeHidden {
                    topBar
                }
                picture
                    .clipShape(RoundedRectangle(cornerRadius: chromeHidden ? 0 : 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: chromeHidden ? 0 : 20, style: .continuous)
                            .strokeBorder(controller.decade.glow.opacity(chromeHidden ? 0 : 0.35), lineWidth: 1.5)
                    )
                    .shadow(color: controller.decade.glow.opacity(chromeHidden ? 0 : 0.3), radius: 24)
                    .padding(.horizontal, chromeHidden ? 0 : 10)
                if !chromeHidden {
                    NowPlayingStrip(controller: controller)
                        .padding(.horizontal, 14)
                    RemoteControl(
                        controller: controller,
                        onEffects: { showEffects = true },
                        onGuide: { showGuide = true }
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            }
            .ignoresSafeArea(.all, edges: chromeHidden ? .all : [])

            if chromeHidden {
                floatingControls
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: chromeHidden)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showEffects) {
            EffectsSheet(controller: controller)
        }
        .sheet(isPresented: $showGuide) {
            GuideSheet(controller: controller)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            UserDefaults.standard.set(controller.decade.id, forKey: "lastDecade")
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                controller.appReturned()
            } else {
                controller.appLeaving()
            }
        }
        .onChange(of: controller.requestedSet) { _, set in
            if let set { onSwitch(set) }
        }
        .onChange(of: chromeHidden) {
            controller.overlayRemote = false
        }
        .onChange(of: controller.overlayRemote) {
            if controller.overlayRemote { scheduleHide() }
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
                Text("The \(controller.decade.id)")
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.cream)
                    .contentTransition(.numericText())
                Text(controller.decade.years)
                    .font(Theme.label(12, weight: .semibold))
                    .foregroundStyle(Theme.dim)
            }
            .animation(.snappy, value: controller.decade)
            Spacer()
            if controller.isLoading {
                ProgressView().tint(Theme.amber)
            }
            CircleIconButton(symbol: "arrow.clockwise", label: "Reload") {
                Haptics.click()
                controller.reload()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
                if controller.isFullScreen {
                    CircleIconButton(symbol: "arrow.down.right.and.arrow.up.left", label: "Exit full screen") {
                        controller.press(.fullScreen)
                    }
                }
                CircleIconButton(symbol: controller.overlayRemote ? "xmark" : "av.remote", label: "Remote") {
                    Haptics.click()
                    controller.overlayRemote.toggle()
                }
            }
            .padding(14)
            .opacity(controller.overlayRemote ? 1 : 0.5)

            if controller.toastVisible && !controller.overlayRemote {
                LEDDisplay(text: controller.ledText)
                    .frame(width: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if controller.overlayRemote {
                overlayRemote
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: controller.overlayRemote)
    }

    @ViewBuilder
    private var overlayRemote: some View {
        let remote = RemoteControl(
            controller: controller,
            compact: true,
            onEffects: { showEffects = true },
            onGuide: { showGuide = true }
        )
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

    private func scheduleHide() {
        hideRemote?.cancel()
        hideRemote = Task {
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            controller.overlayRemote = false
        }
    }

    // MARK: Picture

    private var picture: some View {
        ZStack {
            Color.black
            RetroWebView(controller: controller)
                .opacity(controller.hasError ? 0 : 1)

            if controller.isLoading && !controller.hasError {
                TuningOverlay(decade: controller.decade)
                    .transition(.opacity)
            }
            if controller.hasError {
                NoSignalView { controller.reload() }
                    .transition(.opacity)
            }
            PowerOnFlash()
                .id(controller.tuneCount)

            if let banner = controller.banner {
                VStack {
                    Text(banner)
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
                .id(banner)
            }
        }
        .animation(.easeOut(duration: 0.35), value: controller.isLoading)
        .animation(.easeOut(duration: 0.25), value: controller.hasError)
    }
}

/// Snow and a channel readout while a set loads.
struct TuningOverlay: View {
    let decade: Decade

    var body: some View {
        ZStack {
            StaticNoise(cell: 4, brightness: 0.55)
            VStack(spacing: 6) {
                Text(decade.id)
                    .font(Theme.display(54))
                    .foregroundStyle(.white)
                    .shadow(color: decade.glow, radius: 14)
                Text(L10n.tvTuning)
                    .font(Theme.led(14))
                    .foregroundStyle(Theme.amber)
                    .shadow(color: Theme.amber, radius: 6)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.55)))
        }
        .allowsHitTesting(false)
    }
}

/// Shown when a set can't load (no connection).
struct NoSignalView: View {
    let retry: () -> Void

    var body: some View {
        ZStack {
            StaticNoise(cell: 6, brightness: 0.25)
            VStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                Text(L10n.tvOfflineTitle)
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.cream)
                Text(L10n.tvOfflineBody)
                    .font(Theme.label(14, weight: .medium))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
                Button {
                    Haptics.click()
                    retry()
                } label: {
                    Text(L10n.tvRetry)
                        .font(Theme.label(15, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Theme.amber))
                }
                .buttonStyle(PressableStyle())
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.black.opacity(0.75)))
            .padding(20)
        }
    }
}

struct CircleIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.cream)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .accessibilityLabel(label)
    }
}
