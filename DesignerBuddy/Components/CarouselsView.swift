import SwiftUI

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

    // MARK: - Data

    private let covers: [CoverItem] = [
        CoverItem(title: "Aurora",   subtitle: "Ambient",   symbol: "moon.stars.fill",      colors: [.indigo, .purple]),
        CoverItem(title: "Pulse",    subtitle: "Electronic", symbol: "waveform.path",        colors: [.pink, .orange]),
        CoverItem(title: "Tide",     subtitle: "Chill",      symbol: "water.waves",          colors: [.teal, .blue]),
        CoverItem(title: "Ember",    subtitle: "Acoustic",   symbol: "flame.fill",           colors: [.orange, .red]),
        CoverItem(title: "Meadow",   subtitle: "Folk",       symbol: "leaf.fill",            colors: [.green, .mint]),
        CoverItem(title: "Nocturne", subtitle: "Classical",  symbol: "pianokeys",            colors: [.blue, .indigo]),
    ]

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

            Color.clear.frame(height: 8)
        }
        .navigationTitle("Carousels")
        .navigationBarTitleDisplayMode(.inline)
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
                                    content
                                        .rotation3DEffect(
                                            .degrees(phase.value * -55),
                                            axis: (x: 0, y: 1, z: 0),
                                            anchor: .center,
                                            perspective: 0.5
                                        )
                                        .scaleEffect(1 - abs(phase.value) * 0.22)
                                        .opacity(1 - abs(phase.value) * 0.25)
                                        // Pull neighbours toward the centered card for the overlapped, stacked look.
                                        .offset(x: -phase.value * 28)
                                        // Keep the centered card drawn on top of its rotated neighbours.
                                        .zIndex(1 - Double(abs(phase.value)))
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

            pageControl
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

            captionText(".scrollTargetBehavior(.paging) + .scrollPosition(id:) drives the dots")
                .padding(.horizontal, 16)
        }
    }

    private var pageControl: some View {
        HStack(spacing: 8) {
            ForEach(covers.indices, id: \.self) { index in
                Capsule()
                    .fill(index == (pagedPosition ?? 0) ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == (pagedPosition ?? 0) ? 20 : 7, height: 7)
            }
        }
        .animation(.snappy(duration: 0.3), value: pagedPosition)
        .sensoryFeedback(.selection, trigger: pagedPosition)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        CarouselsView()
    }
}
