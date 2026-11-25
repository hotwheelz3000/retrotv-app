import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                TVSetView(decade: Decade.all[3], showsLabel: false)
                    .frame(width: 120)
                    .padding(.top, 10)

                VStack(spacing: 6) {
                    Text(L10n.appName)
                        .font(Theme.display(28))
                        .foregroundStyle(Theme.cream)
                    Text(BuildInfo.label)
                        .font(Theme.label(13, weight: .medium))
                        .foregroundStyle(Theme.dim)
                }

                Text(
                    "An unofficial app for MyRetroTVs, the free retro TV simulator, and MTV Rewind "
                        + "(wantmymtv.org), music videos 24/7. It isn't made by or affiliated with either site. "
                        + "Every TV set, channel and clip comes from those sites and YouTube."
                )
                .font(Theme.label(15, weight: .medium))
                .foregroundStyle(Theme.cream.opacity(0.85))
                .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    linkRow("Open myretrotvs.com", symbol: "safari", url: "https://www.myretrotvs.com")
                    linkRow("Support MyRetroTVs", symbol: "cup.and.saucer", url: "https://www.buymeacoffee.com/myretrotvs")
                    linkRow("Open wantmymtv.org", symbol: "music.note.tv", url: "https://wantmymtv.org")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("TIPS")
                        .font(Theme.label(12, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Theme.amber)
                    gesture("arrow.up.arrow.down", "Swipe up or down on the TV to change channels (in Focus or Full)")
                    gesture("arrow.left.arrow.right", "Swipe left or right to change decades")
                    gesture("list.bullet.rectangle", "Guide (or tap the LED): what's on, years and channel picks")
                    gesture("arrow.up.left.and.arrow.down.right", "Full: video fills the screen; tap the picture for the remote")
                    gesture("rotate.right", "Turn your phone sideways for a full-screen TV")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panelHigh))
            }
            .padding(20)
        }
        .background(Theme.panel.ignoresSafeArea())
        .navigationTitle(L10n.aboutTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linkRow(_ title: String, symbol: String, url: String) -> some View {
        Button {
            if let link = URL(string: url) { openURL(link) }
        } label: {
            HStack {
                Image(systemName: symbol).foregroundStyle(Theme.amber)
                Text(title).foregroundStyle(Theme.cream)
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(Theme.dim)
            }
            .font(Theme.label(15, weight: .semibold))
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panelHigh))
        }
        .buttonStyle(PressableStyle(scale: 0.97))
    }

    private func gesture(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 22)
                .foregroundStyle(Theme.amber)
            Text(text)
                .foregroundStyle(Theme.cream.opacity(0.85))
        }
        .font(Theme.label(14, weight: .medium))
    }
}
