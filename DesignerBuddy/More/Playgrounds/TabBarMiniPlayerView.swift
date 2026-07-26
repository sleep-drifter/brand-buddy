import SwiftUI

// Tab bar → mini player tear-off. A now-playing pill rests against a glass
// tab bar, necked into it by the container's blend. Dragging the pill up
// tears its glass free and inflates it into a full player card while the bar
// shrinks away — every attribute is linear in one progress value, so the drag
// tracks the finger continuously and the release spring follows the same path.

struct TabBarMiniPlayerView: View {
    @State private var progress: Double = 0
    @State private var dragBase: Double?

    @State private var travel: Double = 150
    @State private var blend: Double = 26
    @State private var tinted = true
    @State private var background: StageBG = .blobs

    private enum StageBG: String, CaseIterable, Identifiable {
        case blobs = "Blobs", gradient = "Gradient", mesh = "Mesh"
        var id: String { rawValue }
    }

    private var snapSpring: Animation { .spring(response: 0.45, dampingFraction: 0.82) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Tab Mini Player") {
            stage
        }
        .navigationTitle("Tab Mini Player")
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack {
            stageBackground
            GeometryReader { geo in
                stageContent(width: geo.size.width)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var stageBackground: some View {
        switch background {
        case .blobs:
            BlobBackground()
        case .gradient:
            LinearGradient(colors: [.indigo, .cyan],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mesh:
            Rectangle().fill(MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [.red, .orange, .yellow, .purple, .pink, .orange, .blue, .cyan, .green]))
        }
    }

    private func stageContent(width: CGFloat) -> some View {
        let p = CGFloat(progress)
        return GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack(alignment: .bottom) {
                tabBar(width: width)
                    .scaleEffect(1 - 0.07 * p)
                    .offset(y: 14 * p)
                    .padding(.bottom, 12)
                player(width: width, p: p)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func tabBar(width: CGFloat) -> some View {
        HStack {
            ForEach(["house.fill", "magnifyingglass", "square.stack", "person.fill"], id: \.self) { s in
                Image(systemName: s)
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: width - 44, height: 54)
        .glassEffect(.regular, in: .capsule)
    }

    private func player(width: CGFloat, p: CGFloat) -> some View {
        let w = (width - 84) + 54 * p
        let h = 44 + 86 * p
        let glass: Glass = tinted ? .regular.tint(.purple.opacity(0.55)) : .regular
        return ZStack {
            miniContent.opacity(Double(1 - p))
            fullContent.opacity(Double(p))
        }
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .frame(width: w, height: h)
        .glassEffect(glass, in: .rect(cornerRadius: 22))
        .offset(y: -74 + 22 * p)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture { snap(to: progress < 0.5 ? 1 : 0) }
        .gesture(playerDrag)
    }

    private var miniContent: some View {
        HStack(spacing: 10) {
            art(size: 28, radius: 7)
            Text("Nocturne — drift")
                .font(.caption.weight(.medium))
                .lineLimit(1)
            Spacer()
            Image(systemName: "play.fill").font(.system(size: 14))
        }
        .padding(.horizontal, 12)
    }

    private var fullContent: some View {
        VStack(spacing: 10) {
            art(size: 54, radius: 12)
            Text("Nocturne — drift").font(.subheadline.weight(.semibold))
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 150, height: 4)
                .overlay(alignment: .leading) {
                    Capsule().fill(.primary).frame(width: 56, height: 4)
                }
            HStack(spacing: 26) {
                Image(systemName: "backward.fill")
                Image(systemName: "play.fill").font(.system(size: 20))
                Image(systemName: "forward.fill")
            }
            .font(.system(size: 15))
        }
        .padding(.vertical, 10)
    }

    private func art(size: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(LinearGradient(colors: [.pink, .purple],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "waveform")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white)
            )
    }

    private var playerDrag: some Gesture {
        DragGesture()
            .onChanged { v in
                if dragBase == nil { dragBase = progress }
                let base = dragBase ?? progress
                progress = min(max(base - Double(v.translation.height) / travel, 0), 1)
            }
            .onEnded { v in
                let base = dragBase ?? progress
                dragBase = nil
                let predicted = base - Double(v.predictedEndTranslation.height) / travel
                snap(to: predicted > 0.5 ? 1 : 0)
            }
    }

    private func snap(to value: Double) {
        if value == 1 { glassMorphHaptic(.soft) }
        withAnimation(snapSpring) { progress = value }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            scrubRow
            divider
            sliderRow("Travel", $travel, 100...220, text: "\(Int(travel))")
            divider
            sliderRow("Blend", $blend, 0...64, text: "\(Int(blend))")
            divider
            row { Toggle("Tint Glass", isOn: $tinted) }
            divider
            row {
                HStack {
                    Text("Background").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Background", selection: $background) {
                        ForEach(StageBG.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 210)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scrubRow: some View {
        row {
            HStack(spacing: 12) {
                Text("Scrub").frame(width: 96, alignment: .leading)
                Slider(value: $progress, in: 0...1) { editing in
                    if !editing { snap(to: progress.rounded()) }
                }
                Text(String(format: "%.2f", progress))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
            }
        }
    }

    private var caption: some View {
        Text("The pill rests a few points above the bar — inside the container's "
             + "Blend distance, so the two read as one necked piece of chrome. Dragging "
             + "up maps finger travel onto a single progress value; the pill's glass "
             + "tears free of the bar, inflates into the card, and the bar shrinks away. "
             + "Every animated attribute is linear in that progress, so the release "
             + "spring follows exactly the path the finger was on. This is the Apple "
             + "Music iOS 26 move — drag, flick, tap, or scrub it.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Row helpers

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                Slider(value: value, in: range)
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
    NavigationStack { TabBarMiniPlayerView() }
        .environmentObject(PinsStore())
}
