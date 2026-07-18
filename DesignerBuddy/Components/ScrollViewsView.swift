import SwiftUI

// MARK: - Models

private struct PagingItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Main View

struct ScrollViewsView: View {

    // Section 5: scroll position tracking
    @State private var scrollPosition: Int? = nil

    // MARK: - Data

    private let basicCardColors: [Color] = [.blue, .green, .orange, .purple, .pink]

    private let lazyRowColors: [Color] = [.blue, .green, .orange, .purple]

    private let pagingItems: [PagingItem] = [
        PagingItem(title: "Discover", subtitle: "Explore new content",    color: .blue),
        PagingItem(title: "Create",   subtitle: "Build something great",  color: .purple),
        PagingItem(title: "Share",    subtitle: "Reach your audience",    color: .orange),
        PagingItem(title: "Connect",  subtitle: "Grow your community",    color: .teal),
    ]

    private let edgeFadeItems = [
        "SwiftUI", "UIKit", "Combine", "AsyncAwait", "Concurrency",
        "Generics", "Protocols", "Extensions", "PropertyWrappers", "ViewModifiers",
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                basicHorizontalSection
                lazyVerticalSection
            }
            .padding(16)

            // Section 3: full-bleed paging — no horizontal padding
            pagingSection

            VStack(spacing: 24) {
                edgeFadeSection
                scrollPositionSection
            }
            .padding(16)
        }
        .navigationTitle("Scroll Views")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section 1: Basic Horizontal Scroll

    private var basicHorizontalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Basic Horizontal Scroll")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(basicCardColors.enumerated()), id: \.offset) { index, color in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.gradient)
                            .frame(width: 160, height: 100)
                            .overlay(
                                Text("Item \(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.horizontal, -16)

            captionText("Horizontal scroller — cards overflow the edge to invite a swipe")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 2: Vertical Scroll with Lazy Loading

    private var lazyVerticalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Vertical Scroll with Lazy Loading")

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(1...20, id: \.self) { i in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(lazyRowColors[(i - 1) % lazyRowColors.count])
                                .frame(width: 10, height: 10)
                            Text("Row \(i)")
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)

                        if i < 20 {
                            Divider()
                        }
                    }
                }
            }
            .frame(height: 240)

            captionText("Rows load lazily as they scroll into view — smooth even for very tall lists")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 3: Snapping — Paging (full-bleed)

    private var pagingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snapping — paging")
                .font(.headline)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(pagingItems) { item in
                        RoundedRectangle(cornerRadius: 0)
                            .fill(item.color.gradient)
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                            .overlay(
                                VStack(spacing: 8) {
                                    Text(item.title)
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                    Text(item.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .frame(height: 200)

            Text("Full-width pages snap one screen at a time")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
    }

    // MARK: - Section 4: Horizontal Edge Fade

    private var edgeFadeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Horizontal — edge fade")

            if #available(iOS 26, *) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(edgeFadeItems, id: \.self) { item in
                            tagPill(item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollEdgeEffectStyle(.soft, for: .horizontal)
            } else {
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(edgeFadeItems, id: \.self) { item in
                                tagPill(item)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    HStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color(.systemBackground), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40)

                        Spacer()

                        LinearGradient(
                            colors: [.clear, Color(.systemBackground)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40)
                    }
                    .allowsHitTesting(false)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                captionText("iOS 26+: the soft edge fade is a built-in scroll effect")
                captionText("iOS 17 fallback: gradient overlays on the leading and trailing edges")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section 5: Scroll Position Tracking

    private var scrollPositionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Scroll Position Tracking")

            HStack {
                Text("Visible item:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(scrollPosition.map { "#\($0)" } ?? "—")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.default, value: scrollPosition)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...12, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(scrollPosition == i ? 1.0 : 0.3))
                            .frame(width: 140, height: 80)
                            .overlay(
                                Text("Item \(i)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            )
                            .id(i)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 2)
            }
            .scrollPosition(id: $scrollPosition)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .padding(.horizontal, -16)

            captionText("The readout above tracks the leading-aligned item as you scroll")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func captionText(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func tagPill(_ label: String) -> some View {
        Text(label)
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollViewsView()
    }
}
