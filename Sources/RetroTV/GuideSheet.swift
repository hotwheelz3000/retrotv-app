import SwiftUI

/// The channel guide: what's on now, the decade's years, and the content categories.
struct GuideSheet: View {
    let controller: TVController
    @Environment(\.dismiss) private var dismiss

    private let yearColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nowPlaying
                    years
                    categories
                }
                .padding(18)
            }
            .background(Theme.panel.ignoresSafeArea())
            .navigationTitle("Guide · The \(controller.decade.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(Theme.label(16, weight: .bold))
                        .tint(Theme.amber)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.panel)
    }

    // MARK: Now playing

    private var nowPlaying: some View {
        VStack(alignment: .leading, spacing: 10) {
            header("Now playing")
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black)
                    Image(systemName: "tv")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(controller.decade.glow)
                        .shadow(color: controller.decade.glow, radius: 6)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(controller.nowTitle.isEmpty ? "Turn the TV on to see what's playing" : controller.nowTitle)
                        .font(Theme.label(16, weight: .bold))
                        .foregroundStyle(controller.nowTitle.isEmpty ? Theme.dim : Theme.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    if !controller.channelLabel.isEmpty {
                        HStack(spacing: 8) {
                            if !controller.nowCategory.isEmpty {
                                CategoryChip(text: controller.nowCategory, color: controller.decade.glow)
                            }
                            if let number = controller.channelNumber {
                                Text("CH \(number)")
                                    .font(Theme.led(13))
                                    .foregroundStyle(Theme.amber)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                guideButton("chevron.down", "CH") { controller.press(.channelDown) }
                guideButton("chevron.up", "CH") { controller.press(.channelUp) }
                guideButton("play.rectangle", "YouTube") { controller.press(.youtube) }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.panelHigh))
    }

    private func guideButton(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(title)
            }
            .font(Theme.label(13, weight: .bold))
            .foregroundStyle(Theme.cream)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Years

    @ViewBuilder
    private var years: some View {
        if !controller.years.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                header("Years")
                LazyVGrid(columns: yearColumns, spacing: 8) {
                    ForEach(controller.years) { year in
                        Button {
                            controller.selectYear(year)
                        } label: {
                            Text(year.name)
                                .font(Theme.label(15, weight: .heavy))
                                .foregroundStyle(year.selected ? Color.black : Theme.cream)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(year.selected ? controller.decade.glow : Theme.panelHigh)
                                        .shadow(color: year.selected ? controller.decade.glow.opacity(0.6) : .clear, radius: 8)
                                )
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityAddTraits(year.selected ? .isSelected : [])
                    }
                }
            }
            .animation(.snappy, value: controller.years)
        }
    }

    // MARK: Categories

    @ViewBuilder
    private var categories: some View {
        if !controller.categories.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    header("Channels")
                    Spacer()
                    Button("All") { controller.selectAllCategories(true) }
                    Text("·").foregroundStyle(Theme.dim)
                    Button("None") { controller.selectAllCategories(false) }
                }
                .font(Theme.label(14, weight: .bold))
                .tint(Theme.amber)

                Text("Pick what plays. The TV switches channel to apply your picks.")
                    .font(Theme.label(12, weight: .medium))
                    .foregroundStyle(Theme.dim)

                VStack(spacing: 0) {
                    ForEach(Array(controller.categories.enumerated()), id: \.element.id) { index, category in
                        if index > 0 {
                            Divider().overlay(Theme.stroke).padding(.leading, 14)
                        }
                        Toggle(isOn: Binding(
                            get: { category.checked },
                            set: { controller.setCategory(category.code, on: $0) }
                        )) {
                            HStack {
                                Text(category.name)
                                    .font(Theme.label(15, weight: .semibold))
                                    .foregroundStyle(Theme.cream)
                                Spacer()
                                Text(category.count.formatted())
                                    .font(Theme.led(12))
                                    .foregroundStyle(Theme.dim)
                            }
                        }
                        .tint(Theme.amber)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.panelHigh))

                if !controller.categories.contains(where: \.checked) {
                    Label("Nothing selected: pick at least one to keep the TV playing.", systemImage: "exclamationmark.triangle")
                        .font(Theme.label(12, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
            }
        }
    }

    private func header(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Theme.label(12, weight: .heavy))
            .tracking(1.2)
            .foregroundStyle(Theme.amber)
    }
}

struct CategoryChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(Theme.label(10, weight: .heavy))
            .tracking(0.8)
            .foregroundStyle(Color.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule(style: .continuous).fill(color))
    }
}

/// The clip title under the TV, scrolling when it doesn't fit. (The Guide button opens the guide.)
struct NowPlayingStrip: View {
    let controller: TVController

    var body: some View {
        HStack(spacing: 10) {
            if !controller.nowCategory.isEmpty {
                CategoryChip(text: controller.nowCategory, color: controller.decade.glow)
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(controller.decade.glow)
            }
            Marquee(text: controller.nowTitle.isEmpty ? "Press power to start" : controller.nowTitle)
                .frame(height: 20)
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(Capsule(style: .continuous).fill(Theme.panel))
        .overlay(Capsule(style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(controller.nowTitle.isEmpty ? "Nothing playing" : "Now playing: \(controller.nowTitle)")
    }
}

/// Text that slowly scrolls sideways when it's wider than its space.
struct Marquee: View {
    let text: String
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let overflow = textWidth - proxy.size.width
            Text(text)
                .font(Theme.label(14, weight: .semibold))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
                .fixedSize()
                .background(
                    GeometryReader { inner in
                        Color.clear
                            .onAppear { textWidth = inner.size.width }
                            .onChange(of: inner.size.width) { _, width in textWidth = width }
                    }
                )
                .offset(x: overflow > 0 ? offset : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .clipped()
                .task(id: "\(text)|\(Int(overflow))") {
                    offset = 0
                    guard overflow > 0 else { return }
                    try? await Task.sleep(for: .seconds(1.5))
                    while !Task.isCancelled {
                        withAnimation(.linear(duration: Double(overflow) / 30)) { offset = -overflow }
                        try? await Task.sleep(for: .seconds(Double(overflow) / 30 + 1.5))
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeInOut(duration: 0.4)) { offset = 0 }
                        try? await Task.sleep(for: .seconds(2))
                    }
                }
        }
        .clipped()
    }
}
