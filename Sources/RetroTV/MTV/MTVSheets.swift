import SwiftUI

/// The look shared by every sheet: a dark panel, a title and a Done button.
private struct SheetFrame<Content: View>: View {
    let title: String
    var detents: Set<PresentationDetent> = [.medium, .large]
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .environment(\.defaultMinListRowHeight, 52)
                .scrollContentBackground(.hidden)
                .background(MTVTheme.background.ignoresSafeArea())
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .font(MTVTheme.label(16, weight: .bold))
                            .tint(MTVTheme.pink)
                    }
                }
        }
        .presentationDetents(detents)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Metrics.cardRadius + 4)
        .presentationBackground(MTVTheme.background)
        .preferredColorScheme(.dark)
    }
}

private struct Placeholder: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: Metrics.md) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(MTVTheme.dim)
                .frame(width: 64, height: 64)
                .background(Circle().fill(MTVTheme.navy))
                .overlay(Circle().strokeBorder(MTVTheme.royal.opacity(0.5), lineWidth: 1))
            Text(text)
                .font(MTVTheme.label(15))
                .foregroundStyle(MTVTheme.dim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metrics.xl)
    }
}

// MARK: Channels

struct ChannelsSheet: View {
    let player: PlayerController
    @State private var sections: [ChannelSection]?
    @State private var filter = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetFrame(title: "Channels") {
            Group {
                if let sections {
                    List {
                        ForEach(filtered(sections)) { section in
                            Section {
                                ForEach(section.channels) { channel in
                                    row(channel)
                                }
                            } header: {
                                Text(section.name.uppercased())
                                    .font(MTVTheme.led(11))
                                    .tracking(0.6)
                                    .foregroundStyle(MTVTheme.yellow)
                                    .padding(.top, Metrics.sm)
                            }
                            .listRowBackground(MTVTheme.navy)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $filter, prompt: "Find a channel")
                } else {
                    ProgressView().tint(MTVTheme.pink).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task { sections = await player.channels() }
    }

    private func row(_ channel: Channel) -> some View {
        let on = channel.key == player.now.channel
        return Button {
            player.tune(channel)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(channel.icon).font(.system(size: 22)).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(MTVTheme.label(15, weight: .bold))
                        .foregroundStyle(on ? MTVTheme.pink : MTVTheme.text)
                    if channel.count >= 1 {
                        Text("\(channel.count.formatted()) videos")
                            .font(MTVTheme.label(12))
                            .foregroundStyle(MTVTheme.dim)
                    }
                }
                Spacer()
                if on {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundStyle(MTVTheme.pink)
                }
            }
        }
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func filtered(_ sections: [ChannelSection]) -> [ChannelSection] {
        let query = filter.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sections }
        return sections.compactMap { section in
            let matches = section.channels.filter { $0.name.localizedCaseInsensitiveContains(query) }
            return matches.isEmpty ? nil : ChannelSection(id: section.id, name: section.name, channels: matches)
        }
    }
}

// MARK: Time Machine

struct TimeMachineSheet: View {
    let player: PlayerController
    @State private var years: [Int]?
    @State private var decade = 1980
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        SheetFrame(title: "Time Machine") {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Set the dial. Tune into the year.")
                        .font(MTVTheme.label(15))
                        .foregroundStyle(MTVTheme.dim)
                    if let years, !years.isEmpty {
                        decadeDial(years)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(years.filter { $0 / 10 * 10 == decade }, id: \.self) { year in
                                Button {
                                    player.tune(year: year)
                                    dismiss()
                                } label: {
                                    Text(String(year))
                                        .font(MTVTheme.led(17))
                                        .foregroundStyle(MTVTheme.yellow)
                                        .shadow(color: MTVTheme.yellow.opacity(0.6), radius: 4)
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(MTVTheme.navy)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .strokeBorder(MTVTheme.royal.opacity(0.6), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(MTVPressableStyle())
                            }
                        }
                        Button {
                            let pool = years.filter { $0 / 10 * 10 == decade }
                            if let year = pool.randomElement() {
                                player.tune(year: year)
                                dismiss()
                            }
                        } label: {
                            Label("Surprise me from the \(decadeName(decade))", systemImage: "shuffle")
                                .font(MTVTheme.label(15, weight: .bold))
                                .foregroundStyle(MTVTheme.ink)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(MTVTheme.yellow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(MTVTheme.ink, lineWidth: 2)
                                )
                        }
                        .buttonStyle(MTVPressableStyle())
                    } else if years == nil {
                        ProgressView().tint(MTVTheme.pink).frame(maxWidth: .infinity)
                    } else {
                        Placeholder(symbol: "clock", text: "The Time Machine is still loading. Try again in a moment.")
                    }
                }
                .padding(18)
            }
        }
        .task {
            let list = await player.years()
            years = list
            if let mid = list.first(where: { $0 >= 1980 }) ?? list.first { decade = mid / 10 * 10 }
        }
    }

    private func decadeDial(_ years: [Int]) -> some View {
        let decades = Array(Set(years.map { $0 / 10 * 10 })).sorted()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(decades, id: \.self) { d in
                    let on = d == decade
                    Button {
                        MTVHaptics.tick()
                        decade = d
                    } label: {
                        Text(decadeName(d))
                            .font(MTVTheme.label(15, weight: .heavy))
                            .foregroundStyle(on ? MTVTheme.ink : MTVTheme.dim)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 38)
                            .background(
                                Capsule().fill(on ? MTVTheme.yellow : MTVTheme.navy)
                                    .shadow(color: on ? MTVTheme.yellow.opacity(0.6) : .clear, radius: 8)
                            )
                    }
                    .buttonStyle(MTVPressableStyle())
                }
            }
        }
        .animation(.snappy, value: decade)
    }

    private func decadeName(_ d: Int) -> String {
        d < 2000 ? "\(d % 100)s" : "\(d)s"
    }
}

// MARK: Search

struct SearchSheet: View {
    let player: PlayerController
    @State private var query = ""
    @State private var results: [Track] = []
    @State private var searching = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetFrame(title: "Search", detents: [.large]) {
            List {
                ForEach(results) { track in
                    Button {
                        player.play(track)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(MTVTheme.label(15, weight: .bold))
                                .foregroundStyle(MTVTheme.text)
                            Text(track.artist)
                                .font(MTVTheme.label(13))
                                .foregroundStyle(MTVTheme.salmon)
                        }
                    }
                    .listRowBackground(MTVTheme.navy)
                }
            }
            .listStyle(.plain)
            .overlay {
                if searching && results.isEmpty {
                    ProgressView().tint(MTVTheme.pink)
                } else if results.isEmpty {
                    Placeholder(
                        symbol: "magnifyingglass",
                        text: query.isEmpty ? "Search 113,000+ videos by artist or song." : "No videos found."
                    )
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Artist or song")
            .task(id: query) {
                let q = query.trimmingCharacters(in: .whitespaces)
                guard q.count >= 2 else { results = []; return }
                try? await Task.sleep(for: .milliseconds(300))
                if Task.isCancelled { return }
                searching = true
                let found = await player.search(q)
                if !Task.isCancelled { results = found }
                searching = false
            }
        }
    }
}

// MARK: Saved

struct SavedSheet: View {
    let player: PlayerController
    @State private var videos: [SavedVideo]?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetFrame(title: "Saved") {
            Group {
                if let videos, !videos.isEmpty {
                    List {
                        Section {
                            Button {
                                player.playAllSaved()
                                dismiss()
                            } label: {
                                Label("Play all \(videos.count)", systemImage: "play.fill")
                                    .font(MTVTheme.label(15, weight: .bold))
                                    .foregroundStyle(MTVTheme.pink)
                            }
                            .listRowBackground(MTVTheme.navy)
                        }
                        Section {
                            ForEach(Array(videos.enumerated()), id: \.offset) { index, video in
                                Button {
                                    player.playSaved(at: index)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(MTVTheme.led(13))
                                            .foregroundStyle(MTVTheme.dim)
                                            .frame(width: 26)
                                        Text(video.title.isEmpty ? "Video \(index + 1)" : video.title)
                                            .font(MTVTheme.label(15, weight: .semibold))
                                            .foregroundStyle(MTVTheme.text)
                                    }
                                }
                                .listRowBackground(MTVTheme.navy)
                            }
                            .onDelete { offsets in
                                for index in offsets.sorted(by: >) { player.removeSaved(at: index) }
                                self.videos?.remove(atOffsets: offsets)
                            }
                        } footer: {
                            Text("Tap ♥ Save on the remote to add the video that's playing. Swipe left to remove.")
                                .foregroundStyle(MTVTheme.dim)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if videos == nil {
                    ProgressView().tint(MTVTheme.pink).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Placeholder(symbol: "heart", text: "Nothing saved yet.\nTap ♥ Save on the remote to keep a video.")
                }
            }
        }
        .task { videos = await player.saved() }
    }
}
