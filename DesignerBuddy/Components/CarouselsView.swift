import SwiftUI
import Combine

// MARK: - Models

private struct CoverItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let colors: [Color]

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Main View

struct CarouselsView: View {

    // Section 3: paged carousel — tracks the centered page for the page control.
    @State private var pagedPosition: Int? = 0

    // Section 4: auto-advancing banner.
    @State private var bannerPosition: Int? = 0
    @State private var autoAdvance = true
    private let bannerTimer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    // Section 5: infinite loop.
    @State private var loopPosition: Int?

    // Section 6: Wallet-style deck.
    @State private var deckExpanded = false

    // Section 7: full-screen vertical stories.
    @State private var showStories = false

    // MARK: - Data

    private let covers: [CoverItem] = [
        CoverItem(title: "Aurora",   subtitle: "Ambient",    symbol: "moon.stars.fill",  colors: [.indigo, .purple]),
        CoverItem(title: "Pulse",    subtitle: "Electronic", symbol: "waveform.path",    colors: [.pink, .orange]),
        CoverItem(title: "Tide",     subtitle: "Chill",      symbol: "water.waves",      colors: [.teal, .blue]),
        CoverItem(title: "Ember",    subtitle: "Acoustic",   symbol: "flame.fill",       colors: [.orange, .red]),
        CoverItem(title: "Meadow",   subtitle: "Folk",       symbol: "leaf.fill",        colors: [.green, .mint]),
        CoverItem(title: "Nocturne", subtitle: "Classical",  symbol: "pianokeys",        colors: [.blue, .indigo]),
    ]

    // Three copies so the loop carousel can wrap seamlessly across the ends.
    private var loopItems: [CoverItem] { covers + covers + covers }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                introText
            }
            .padding(16)

            // Full-bleed sections — no horizontal padding so cards can run edge-to-edge.
            coverFlowSection
            peekingSection
            pagedSection
            bannerSection
            loopSection

            VStack(spacing: 24) {
                walletSection
            }
            .padding(16)

            VStack(spacing: 24) {
                storiesSection
            }
            .padding(16)

            Color.clear.frame(height: 8)
        }
        .navigationTitle("Carousels")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showStories) {
            StoriesPlayer(covers: covers)
        }
    }

    private var introText: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Native carousels")
            Text("Horizontal, snapping carousels built with SwiftUI's scroll target APIs. "
                 + "Each depth effect is driven by scrollTransition, so it tracks the finger "
                 + "and settles centered — no gesture math or UIKit bridging required.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 1: Cover Flow (3D)

    private var coverFlowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Cover Flow — 3D")
                .padding(.horizontal, 16)

            GeometryReader { geo in
                let cardWidth: CGFloat = 200
                let side = max(0, (geo.size.width - cardWidth) / 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(covers) { item in
                            coverCard(item, size: cardWidth)
                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                    // Precompute with explicit types so the type-checker has nothing to infer.
                                    let p = Double(phase.value)
                                    let mag = abs(p)
                                    let angle: Double = p * -55
                                    let scale: CGFloat = 1 - mag * 0.22
                                    let fade: Double = 1 - mag * 0.25
                                    return content
                                        .rotation3DEffect(
                                            .degrees(angle),
                                            axis: (x: 0, y: 1, z: 0),
                                            anchor: .center,
                                            perspective: 0.5
                                        )
                                        .scaleEffect(scale)
                                        .opacity(fade)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
                .contentMargins(.horizontal, side, for: .scrollContent)
            }
            .frame(height: 240)

            captionText(".scrollTransition { .rotation3DEffect(axis: y) } — center-aligned snapping")
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 2: Peeking carousel

    private var peekingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Peeking neighbours")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(covers) { item in
                        wideCard(item)
                            .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 12)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.92, anchor: .center)
                                    .opacity(phase.isIdentity ? 1 : 0.55)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 180)

            captionText(".containerRelativeFrame(count:span:) leaves the next card peeking in")
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 3: Paged carousel with page control

    private var pagedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Paged — with page control")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(covers.enumerated()), id: \.element.id) { index, item in
                        heroPage(item)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $pagedPosition)
            .frame(height: 200)

            pageControl(selected: pagedPosition ?? 0)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
                .sensoryFeedback(.selection, trigger: pagedPosition)

            captionText(".scrollTargetBehavior(.paging) + .scrollPosition(id:) drives the dots")
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 4: Auto-advancing banner

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Auto-advancing")
                Spacer()
                Toggle("Auto", isOn: $autoAdvance)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(covers.enumerated()), id: \.element.id) { index, item in
                        heroPage(item)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $bannerPosition)
            .frame(height: 180)
            // Pause auto-advance whenever the user is touching the carousel.
            .onScrollPhaseChange { _, phase in
                if phase != .idle { autoAdvance = false }
            }
            .onReceive(bannerTimer) { _ in
                guard autoAdvance else { return }
                let next = ((bannerPosition ?? 0) + 1) % covers.count
                withAnimation(.easeInOut(duration: 0.6)) { bannerPosition = next }
            }

            pageControl(selected: bannerPosition ?? 0)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

            captionText("Timer.publish advances .scrollPosition; onScrollPhaseChange pauses on touch")
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 5: Infinite loop

    private var loopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Infinite loop")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(loopItems.enumerated()), id: \.offset) { index, item in
                        wideCard(item)
                            .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 12)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $loopPosition)
            .frame(height: 180)
            .onAppear {
                // Start in the middle copy so there's runway in both directions.
                if loopPosition == nil { loopPosition = covers.count }
            }
            // When scrolling settles near either end, jump by one copy — invisibly, since
            // the destination shows the same item. No animation = no visible seam.
            .onScrollPhaseChange { _, phase in
                guard phase == .idle, let p = loopPosition else { return }
                if p < covers.count {
                    loopPosition = p + covers.count
                } else if p >= covers.count * 2 {
                    loopPosition = p - covers.count
                }
            }

            captionText("Tripled buffer + reset-on-idle for a seamless wrap-around")
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 6: Wallet-style stacked deck

    private var walletSection: some View {
        let cards = Array(covers.prefix(4))
        let cardHeight: CGFloat = 116
        let collapsedPeek: CGFloat = 40
        let expandedGap: CGFloat = 128
        let gap = deckExpanded ? expandedGap : collapsedPeek
        let stackHeight = CGFloat(cards.count - 1) * gap + cardHeight

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Wallet-style deck")

            ZStack(alignment: .top) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { i, item in
                    let yOffset: CGFloat = CGFloat(i) * gap
                    let depthScale: CGFloat = deckExpanded ? 1 : 1 - CGFloat(cards.count - 1 - i) * 0.03
                    walletCard(item, height: cardHeight)
                        .offset(y: yOffset)
                        .scaleEffect(depthScale, anchor: .top)
                        .zIndex(Double(i))
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: stackHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    deckExpanded.toggle()
                }
            }

            captionText("Overlapping ZStack + spring — tap to \(deckExpanded ? "collapse" : "expand")")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 7: Full-screen vertical stories

    private var storiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Full-screen vertical")

            Button {
                showStories = true
            } label: {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                    Text("Open full-screen stories")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .font(.body.weight(.medium))
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            captionText("Vertical .scrollTargetBehavior(.paging) in a fullScreenCover — Reels-style")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Cards

    private func coverCard(_ item: CoverItem, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(item.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: item.symbol)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private func wideCard(_ item: CoverItem) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(item.gradient)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(item.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: item.symbol)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(16)
            }
    }

    private func walletCard(_ item: CoverItem, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(item.gradient)
            .frame(height: height)
            .overlay(alignment: .topLeading) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Image(systemName: item.symbol)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(16)
            }
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private func heroPage(_ item: CoverItem) -> some View {
        item.gradient
            .overlay(
                VStack(spacing: 10) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 44, weight: .semibold))
                    Text(item.title)
                        .font(.title2.bold())
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .foregroundStyle(.white)
            )
    }

    // MARK: - Helpers

    private func pageControl(selected: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(covers.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selected ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == selected ? 20 : 7, height: 7)
            }
        }
        .animation(.snappy(duration: 0.3), value: selected)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func captionText(_ text: String) -> some View {
        Text(text)
            .font(.mono(.caption2))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Full-screen Stories Player

private struct StoriesPlayer: View {
    let covers: [CoverItem]
    @Environment(\.dismiss) private var dismiss
    @State private var position: Int? = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(covers.enumerated()), id: \.element.id) { index, item in
                    item.gradient
                        .overlay(
                            VStack(spacing: 14) {
                                Image(systemName: item.symbol)
                                    .font(.system(size: 72, weight: .semibold))
                                Text(item.title)
                                    .font(.largeTitle.bold())
                                Text(item.subtitle)
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .foregroundStyle(.white)
                        )
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $position)
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            HStack(spacing: 4) {
                ForEach(covers.indices, id: \.self) { index in
                    Capsule()
                        .fill(.white.opacity(index == (position ?? 0) ? 0.95 : 0.35))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .black.opacity(0.35))
                    .padding(16)
                    .padding(.top, 16)
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CarouselsView()
    }
}
