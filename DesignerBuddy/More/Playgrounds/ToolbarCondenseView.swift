import SwiftUI

// Toolbar condense driven by real scroll physics. The stage holds an actual
// ScrollView; its content offset (via onScrollGeometryChange) maps onto a
// condense progress that slides the title into the action cluster and
// collapses the cluster's spacing until the circles overlap and fuse into a
// single pill. Momentum and rubber-banding drive the morph — flick the list
// and watch the chrome pour together.

struct ToolbarCondenseView: View {
    @State private var scrollY: Double = 0

    @State private var range: Double = 110
    @State private var actionCount: Double = 3
    @State private var blend: Double = 30
    @State private var tinted = false

    private let actionSymbols = ["plus", "magnifyingglass", "slider.horizontal.3", "ellipsis"]

    private var progress: CGFloat {
        CGFloat(min(max(scrollY / max(range, 1), 0), 1))
    }
    private var actions: Int { min(4, max(2, Int(actionCount))) }
    private var chromeGlass: Glass { tinted ? .regular.tint(.indigo.opacity(0.55)) : .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Toolbar Condense") {
            stage
        }
        .navigationTitle("Toolbar Condense")
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 10) {
                    Color.clear.frame(height: 62)
                    ForEach(0..<16, id: \.self) { i in
                        fakeRow(i)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .onScrollGeometryChange(for: Double.self, of: { geo in
                Double(geo.contentOffset.y + geo.contentInsets.top)
            }, action: { _, new in
                scrollY = new
            })

            toolbar
                .padding(.horizontal, 12)
                .padding(.top, 10)
        }
        .frame(height: 240)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }

    private var toolbar: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            HStack {
                titlePill
                Spacer()
                actionCluster
            }
        }
    }

    private var titlePill: some View {
        Text("Library")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, 16)
            .frame(height: 40)
            .glassEffect(chromeGlass, in: .capsule)
            .opacity(Double(1 - progress))
            .offset(x: 44 * progress)
    }

    /// Expanded, the circles sit 8pt apart; condensed, the spacing goes
    /// negative so they overlap and the container fuses them into one pill.
    private var actionCluster: some View {
        HStack(spacing: 8 - 34 * progress) {
            ForEach(0..<actions, id: \.self) { i in
                actionButton(i)
            }
        }
    }

    private func actionButton(_ i: Int) -> some View {
        let isLead = i == actions - 1
        return ZStack {
            Image(systemName: actionSymbols[i])
                .opacity(Double(1 - progress))
            if isLead {
                Image(systemName: "ellipsis")
                    .opacity(Double(progress))
            }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .frame(width: 40, height: 40)
        .glassEffect(chromeGlass, in: .circle)
    }

    private func fakeRow(_ i: Int) -> some View {
        HStack(spacing: 10) {
            Circle().fill(Color(.systemFill)).frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 5) {
                Capsule().fill(Color(.systemFill)).frame(width: 120, height: 8)
                Capsule().fill(Color(.quaternarySystemFill)).frame(width: 80, height: 8)
            }
            Spacer()
            Text("\(i + 1)").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Range", $range, 60...180, text: "\(Int(range))")
            divider
            sliderRow("Actions", $actionCount, 2...4, step: 1, text: "\(actions)")
            divider
            sliderRow("Blend", $blend, 0...64, text: "\(Int(blend))")
            divider
            row { Toggle("Tint Glass", isOn: $tinted) }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var caption: some View {
        Text("The list in the stage really scrolls — `onScrollGeometryChange` maps "
             + "its content offset onto a condense progress over the first Range points. "
             + "The title slides into the action cluster and fades while the cluster's "
             + "spacing goes negative; once the circles overlap, the container fuses "
             + "them into a single pill with an ellipsis. Because the progress rides "
             + "the scroll offset, momentum and rubber-banding animate the morph for "
             + "free — flick the list and watch the chrome pour together and apart.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Row helpers

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, step: Double = 0, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(text).font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

// MARK: - Preview

#Preview {
    NavigationStack { ToolbarCondenseView() }
        .environmentObject(PinsStore())
}
