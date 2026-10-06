import SwiftUI

// Adaptive Layout — designing for width, not device: size classes,
// AnyLayout switching, ViewThatFits, adaptive grids, and
// NavigationSplitView's collapse behavior.

struct AdaptiveLayoutView: View {

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    @State private var fitsWidth = 300.0
    @State private var gridMinimum = 90.0
    @State private var showSplitDemo = false

    var body: some View {
        List {

            // ── Live environment ───────────────────────────────────────────
            Section {
                LabeledContent("Horizontal size class",
                               value: hSize == .regular ? "Regular" : "Compact")
                LabeledContent("Vertical size class",
                               value: vSize == .regular ? "Regular" : "Compact")
                Text("Rotate the phone, run on iPad, or drag into Split View — these update live, and everything below adapts off them.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Size classes ───────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Size Classes", tag: "Reference")) {
                sizeClassRow("iPhone portrait",            h: "Compact", v: "Regular")
                sizeClassRow("iPhone landscape",           h: "Compact", v: "Compact")
                sizeClassRow("iPhone Pro Max landscape",   h: "Regular", v: "Compact")
                sizeClassRow("iPad full screen",           h: "Regular", v: "Regular")
                sizeClassRow("iPad 1/3 Split View",        h: "Compact", v: "Regular")
                HIGNoteRow("Size classes are the unit of adaptivity — an iPad app in 1/3 Split View *is* an iPhone layout. Branch on size class, never on the device model.")
            }

            // ── AnyLayout ──────────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "AnyLayout Switching", tag: "One hierarchy")) {
                Text("The same card, rendered under each size class:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                VStack(spacing: 12) {
                    AdaptiveProfileCard()
                        .environment(\.horizontalSizeClass, .compact)
                    AdaptiveProfileCard()
                        .environment(\.horizontalSizeClass, .regular)
                }
                .padding(.vertical, 4)
                RefCaption("AnyLayout(VStackLayout()) ↔ AnyLayout(HStackLayout())")
                HIGNoteRow("AnyLayout swaps the container while keeping the children's identity — state and animations survive the change, unlike an if/else between two separate stacks.")
            }

            // ── ViewThatFits ───────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "ViewThatFits", tag: "Self-choosing")) {
                HStack {
                    Spacer()
                    ViewThatFits(in: .horizontal) {
                        Label("Add to favorites and sync", systemImage: "star.circle.fill")
                        Label("Favorite", systemImage: "star.circle.fill")
                        Image(systemName: "star.circle.fill")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.18), in: Capsule())
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .fixedSize()
                    Spacer()
                }
                .frame(width: fitsWidth)
                .frame(maxWidth: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.secondary.opacity(0.3),
                                      style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: fitsWidth)
                }
                .padding(.vertical, 6)

                LabeledContent("Available width: \(Int(fitsWidth))pt") {
                    Slider(value: $fitsWidth, in: 70...340)
                        .frame(width: 150)
                }
                RefCaption("ViewThatFits(in: .horizontal) { full; medium; icon }")
                HIGNoteRow("List the candidates from most to least informative — ViewThatFits takes the first one that fits, so order is the fallback policy.")
            }

            // ── Adaptive grid ──────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Adaptive Grid", tag: "Reflow")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: gridMinimum), spacing: 10)],
                          spacing: 10) {
                    ForEach(0..<8, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.12 + Double(i) * 0.04))
                            .frame(height: 56)
                            .overlay {
                                Text("\(i + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }
                    }
                }
                .padding(.vertical, 4)
                .animation(.snappy, value: gridMinimum)

                LabeledContent("Minimum cell: \(Int(gridMinimum))pt") {
                    Slider(value: $gridMinimum, in: 60...180)
                        .frame(width: 150)
                }
                RefCaption("GridItem(.adaptive(minimum:)) — column count falls out of width")
                HIGNoteRow("Adaptive grids are the cheapest adaptivity there is: pick a minimum cell width that keeps content legible and let every screen size derive its own column count.")
            }

            // ── Split view ─────────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "NavigationSplitView", tag: "Collapse")) {
                Button("Open split view demo") { showSplitDemo = true }
                RefCaption("sidebar + detail → collapses to a stack when compact")
                HIGNoteRow("One NavigationSplitView serves both worlds: columns in regular width, a plain push stack in compact. Don't build a separate iPad navigation scheme — let the split view collapse.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                DoDontRow(good: true,  text: "Test the three iPad widths that matter: full screen, 1/2, and 1/3 Split View — the last one is your iPhone layout.")
                DoDontRow(good: true,  text: "Let text columns cap their line length (~60–70 characters) on wide screens instead of stretching edge to edge.")
                DoDontRow(good: false, text: "Don't branch on UIDevice idiom — an iPad can be compact, and an iPhone Pro Max landscape is regular-width.")
                DoDontRow(good: false, text: "Don't hide functionality in compact layouts; reflow it. Smaller screen, same app.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                CodeBlockRow(code: """
                    @Environment(\\.horizontalSizeClass) var hSize

                    var body: some View {
                        let layout = hSize == .regular
                            ? AnyLayout(HStackLayout(spacing: 16))
                            : AnyLayout(VStackLayout(alignment: .leading))
                        layout {
                            Avatar()
                            Details()
                        }
                    }
                    """)
            }
        }
        .navigationTitle("Adaptive Layout")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showSplitDemo) {
            SplitViewDemo()
        }
    }

    private func sizeClassRow(_ context: String, h: String, v: String) -> some View {
        HStack {
            Text(context)
                .font(.subheadline)
            Spacer()
            Text("W: \(h)")
                .font(.caption.weight(.medium))
                .foregroundStyle(h == "Regular" ? .blue : .orange)
            Text("H: \(v)")
                .font(.caption.weight(.medium))
                .foregroundStyle(v == "Regular" ? .blue : .orange)
        }
    }
}

// MARK: - Adaptive card

/// Horizontal in regular width, vertical in compact — same children, same
/// identity, only the container changes.
private struct AdaptiveProfileCard: View {
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        let layout = hSize == .regular
            ? AnyLayout(HStackLayout(spacing: 14))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 10))

        VStack(alignment: .leading, spacing: 8) {
            Text(hSize == .regular ? "Regular width" : "Compact width")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(hSize == .regular ? .blue : .orange)
            layout {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Riley Chen")
                        .font(.subheadline.weight(.semibold))
                    Text("Product designer · usually prototyping something with springs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Split view demo

private struct SplitViewDemo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: String? = "Typography"

    private let topics = ["Typography", "Color", "Spacing", "Materials", "Motion"]

    var body: some View {
        NavigationSplitView {
            List(topics, id: \.self, selection: $selection) { topic in
                Text(topic)
            }
            .navigationTitle("Topics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        } detail: {
            VStack(spacing: 10) {
                Image(systemName: "sidebar.left")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                Text(selection ?? "Pick a topic")
                    .font(.title3.bold())
                Text("Regular width shows sidebar + detail side by side; compact width collapses this into a plain navigation stack.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .navigationTitle(selection ?? "Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    NavigationStack { AdaptiveLayoutView() }
}
