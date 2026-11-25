import MTVRewind
import SwiftUI

/// The living room: all seven TV sets to pick from, plus the MTV Rewind channel.
struct HomeView: View {
    @State private var selected: Decade?
    @State private var showAbout = false
    @State private var showMTV = false
    @AppStorage("lastDecade") private var lastDecadeID = ""

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if let last = Decade.with(id: lastDecadeID) {
                        ResumeCard(decade: last) { open(last) }
                    }
                    MTVRewindCard {
                        Haptics.thunk()
                        showMTV = true
                    }
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Decade.all) { decade in
                            DecadeCard(decade: decade) { open(decade) }
                        }
                    }
                    Text(L10n.homeFooter)
                        .font(Theme.label(12, weight: .medium))
                        .foregroundStyle(Theme.dim.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(item: $selected) { decade in
            TVScreen(decade: decade)
        }
        .fullScreenCover(isPresented: $showMTV) {
            MTVRewindScreen { showMTV = false }
        }
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                AboutView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showAbout = false }
                                .font(Theme.label(16, weight: .bold))
                                .tint(Theme.amber)
                        }
                    }
            }
            .presentationBackground(Theme.panel)
        }
    }

    private func open(_ decade: Decade) {
        Haptics.thunk()
        selected = decade
    }

    private var background: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Theme.amber.opacity(0.16), Color.clear],
                center: .top, startRadius: 10, endRadius: 420
            )
            Scanlines(spacing: 4, opacity: 0.12)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.appName)
                    .font(Theme.display(36))
                    .foregroundStyle(Theme.cream)
                    .shadow(color: Theme.amber.opacity(0.55), radius: 12)
                Text(L10n.homeTagline)
                    .font(Theme.label(15, weight: .medium))
                    .foregroundStyle(Theme.dim)
            }
            Spacer()
            CircleIconButton(symbol: "info", label: "About") {
                Haptics.click()
                showAbout = true
            }
        }
        .padding(.top, 12)
    }
}

struct DecadeCard: View {
    let decade: Decade
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                TVSetView(decade: decade)
                    .padding(.horizontal, 6)
                    .padding(.top, 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(decade.years)
                        .font(Theme.label(13, weight: .heavy))
                        .foregroundStyle(Theme.cream)
                    Text(decade.tagline)
                        .font(Theme.label(12, weight: .medium))
                        .foregroundStyle(Theme.dim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableStyle(scale: 0.96))
        .accessibilityLabel("The \(decade.id), \(decade.tagline)")
    }
}

struct ResumeCard: View {
    let decade: Decade
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                TVSetView(decade: decade, showsLabel: false)
                    .frame(width: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.homeResume)
                        .font(Theme.label(12, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                    Text("Back to the \(decade.id)")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.cream)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(decade.glow))
                    .shadow(color: decade.glow.opacity(0.6), radius: 10)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [decade.glow.opacity(0.22), Theme.panel],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(decade.glow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableStyle(scale: 0.97))
    }
}

/// The eighth set: MTV Rewind (wantmymtv.org), music videos 24/7.
struct MTVRewindCard: View {
    let action: () -> Void

    private let lilac = Color(red: 0.82, green: 0.63, blue: 0.82)
    private let royal = Color(red: 0.18, green: 0.37, blue: 0.69)
    private let pink = Color(red: 0.89, green: 0.44, blue: 0.75)
    private let sky = Color(red: 0.41, green: 0.69, blue: 0.94)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    MTVRewindLogo(size: 24)
                    Text(L10n.homeMtvTagline)
                        .font(Theme.label(12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle().fill(LinearGradient(colors: [pink, sky], startPoint: .leading, endPoint: .trailing))
                    )
                    .shadow(color: pink.opacity(0.5), radius: 10)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [lilac.opacity(0.22), .clear],
                                    center: .topLeading, startRadius: 4, endRadius: 260
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(royal.opacity(0.6), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .accessibilityLabel("MTV Rewind, music videos 24/7")
    }
}
