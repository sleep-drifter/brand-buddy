import SwiftUI

// Button-to-sheet identity morph. A glass "Options" button and a bottom sheet
// share one glassEffectID: tapping the button melts its glass into the panel,
// and dragging the panel below the low detent melts it back. The drag tracks
// the finger continuously between detents, so the morph moment is something
// you steer into rather than trigger.

struct SheetDetentMorphView: View {
    @Namespace private var glassNS

    @State private var presented = false
    @State private var dragHeight: CGFloat?

    @State private var blend: Double = 26
    @State private var cornerRadius: Double = 28
    @State private var tinted = false
    @State private var background: StageBG = .blobs

    private let restHeight: CGFloat = 172

    private enum StageBG: String, CaseIterable, Identifiable {
        case blobs = "Blobs", gradient = "Gradient", mesh = "Mesh"
        var id: String { rawValue }
    }

    private var morphSpring: Animation { .spring(response: 0.42, dampingFraction: 0.82) }
    private var height: CGFloat { dragHeight ?? restHeight }
    private var glass: Glass { tinted ? .regular.tint(.indigo.opacity(0.55)) : .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Sheet Detent Morph") {
            stage
        }
        .navigationTitle("Sheet Detent Morph")
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack(alignment: .bottom) {
            stageBackground
            GlassEffectContainer(spacing: CGFloat(blend)) {
                ZStack(alignment: .bottom) {
                    if presented {
                        sheetPanel
                    } else {
                        optionsButton
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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

    private var optionsButton: some View {
        Label("Options", systemImage: "slider.horizontal.3")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, 22)
            .frame(height: 44)
            .glassEffect(glass, in: .capsule)
            .glassEffectID("sheet", in: glassNS)
            .padding(.bottom, 16)
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(morphSpring) { presented = true }
            }
    }

    private var sheetPanel: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(.secondary.opacity(0.6))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
            Text("Options").font(.headline)
            sheetRow("bell.badge.fill", "Notifications")
            sheetRow("paintbrush.fill", "Appearance")
            Spacer(minLength: 0)
        }
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .opacity(contentOpacity)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .glassEffect(glass, in: .rect(cornerRadius: CGFloat(cornerRadius)))
        .glassEffectID("sheet", in: glassNS)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .gesture(sheetDrag)
    }

    private func sheetRow(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).frame(width: 22)
            Text(title).font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).opacity(0.5)
        }
        .padding(.horizontal, 18)
    }

    /// Sheet content fades out as the panel is dragged toward the dismiss
    /// detent, so the morph back to the button reads as pure glass.
    private var contentOpacity: Double {
        let t = (height - 80) / 70
        return Double(min(max(t, 0), 1))
    }

    private var sheetDrag: some Gesture {
        DragGesture()
            .onChanged { v in
                dragHeight = min(max(restHeight - v.translation.height, 54), 208)
            }
            .onEnded { v in
                let predicted = restHeight - v.predictedEndTranslation.height
                if predicted < 110 {
                    withAnimation(morphSpring) { presented = false }
                    dragHeight = nil
                } else {
                    withAnimation(morphSpring) { dragHeight = nil }
                }
            }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            row { Toggle("Presented", isOn: $presented.animation(morphSpring)) }
            divider
            sliderRow("Blend", $blend, 0...64, text: "\(Int(blend))")
            divider
            sliderRow("Radius", $cornerRadius, 8...48, text: "\(Int(cornerRadius))")
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

    private var caption: some View {
        Text("The button and the sheet are different views sharing one "
             + "`glassEffectID` in a `GlassEffectContainer`, so presenting melts the "
             + "capsule's glass into the panel instead of cross-fading. The drag tracks "
             + "your finger between detents — sheet content fades near the low detent so "
             + "the morph back to the button is pure glass. Drop below the threshold (or "
             + "flick down) to dismiss; the Presented toggle drives the same morph from "
             + "the controls.")
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
    NavigationStack { SheetDetentMorphView() }
        .environmentObject(PinsStore())
}
