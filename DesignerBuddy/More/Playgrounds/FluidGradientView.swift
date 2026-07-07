import SwiftUI
import UIKit

// MARK: - Model

private struct FluidBlob: Identifiable {
    let id = UUID()
    var color: Color
}

// MARK: - View

struct FluidGradientView: View {
    // Elapsed time from launch. Feeding `timeIntervalSinceReferenceDate` (~8e8)
    // into a 32-bit Float quantizes to ~64s steps, freezing the animation.
    private let startDate = Date()

    @State private var speed:      Float = 0.5
    @State private var grain:      Float = 0.4
    @State private var zoom:       Float = 0.5
    @State private var saturation: Float = 1.0
    @State private var softness:   Float = 1.0
    @State private var warp:       Float = 1.0
    @State private var aberration: Float = 0.0
    @State private var vignette:   Float = 0.0
    @State private var hueShift:   Float = 0.0
    @State private var darkBackground = false
    @State private var isPaused = false
    @State private var blobs: [FluidBlob] = FluidGradientView.defaultBlobs

    private static var defaultBlobs: [FluidBlob] {
        [.init(color: Color(red: 1.0, green: 0.5, blue: 0.0)),
         .init(color: Color(red: 0.55, green: 0.2, blue: 0.95, opacity: 0.9))]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                preview
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Fluid Gradient")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Preview

    private var preview: some View {
        TimelineView(.animation(paused: isPaused)) { tl in
            let t = Float(tl.date.timeIntervalSince(startDate))
            GeometryReader { geo in
                Color.black.colorEffect(fluidShader(size: geo.size, time: t))
            }
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
    }

    private func fluidShader(size: CGSize, time: Float) -> Shader {
        let bg: (Float, Float, Float) = darkBackground ? (0.05, 0.05, 0.06) : (0.90, 0.90, 0.90)
        let c = (0..<5).map { i -> (Float, Float, Float, Float) in
            i < blobs.count ? Self.rgba(blobs[i].color) : (0, 0, 0, 0)
        }
        return ShaderLibrary.chromaGradientArt(
            .float2(size),
            .float(time * (speed * 2)),
            .float(grain * 0.2),
            .float(0.5 + zoom),
            .float3(bg.0, bg.1, bg.2),
            .float(saturation),
            .float(softness),
            .float(warp),
            .float(Float(blobs.count)),
            .float4(c[0].0, c[0].1, c[0].2, c[0].3),
            .float4(c[1].0, c[1].1, c[1].2, c[1].3),
            .float4(c[2].0, c[2].1, c[2].2, c[2].3),
            .float4(c[3].0, c[3].1, c[3].2, c[3].3),
            .float4(c[4].0, c[4].1, c[4].2, c[4].3),
            .float(aberration),
            .float(vignette),
            .float(hueShift)
        )
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            blobList
            row {
                HStack {
                    Text("Background").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Background", selection: $darkBackground) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }
            divider
            sliderRow("Speed",      $speed)
            divider
            sliderRow("Grain",      $grain)
            divider
            sliderRow("Zoom",       $zoom)
            divider
            sliderRow("Saturation", $saturation, range: 0...2)
            divider
            sliderRow("Softness",   $softness,   range: 0.5...2)
            divider
            sliderRow("Warp",       $warp,       range: 0...2)
            divider
            sliderRow("Aberration", $aberration)
            divider
            sliderRow("Vignette",   $vignette)
            divider
            sliderRow("Hue Shift",  $hueShift)
            divider
            row {
                HStack(spacing: 16) {
                    Button { isPaused.toggle() } label: {
                        Label(isPaused ? "Play" : "Pause",
                              systemImage: isPaused ? "play.fill" : "pause.fill")
                    }
                    Button(role: .destructive, action: reset) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    Spacer()
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var blobList: some View {
        ForEach($blobs) { $blob in
            blobRow($blob)
            divider
        }
        if blobs.count < 5 {
            row {
                Button(action: addBlob) { Label("Add Blob", systemImage: "plus.circle") }
            }
            divider
        }
    }

    private func blobRow(_ blob: Binding<FluidBlob>) -> some View {
        let idx = blobs.firstIndex { $0.id == blob.wrappedValue.id } ?? 0
        return HStack(spacing: 8) {
            ColorPicker("Blob \(idx + 1)", selection: blob.color, supportsOpacity: true)
            Spacer(minLength: 8)
            Button { move(blob.wrappedValue.id, by: -1) } label: { Image(systemName: "chevron.up") }
                .disabled(idx == 0)
            Button { move(blob.wrappedValue.id, by: 1) } label: { Image(systemName: "chevron.down") }
                .disabled(idx == blobs.count - 1)
            Button(role: .destructive) { delete(blob.wrappedValue.id) } label: { Image(systemName: "trash") }
                .disabled(blobs.count <= 1)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private var caption: some View {
        Text("A generative Metal shader: soft blobs warped by simplex noise. Each blob is its own "
             + "colour layer (with opacity), composited in list order — blobs lower in the list "
             + "paint on top. Reorder with the arrows, add/remove blobs, and tune background, "
             + "saturation, softness and warp. Ports iShader's ChromaGradients (ShaderToy mtKfDG).")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Actions

    private func addBlob() {
        guard blobs.count < 5 else { return }
        let hue = Double(blobs.count) / 5.0
        blobs.append(.init(color: Color(hue: hue, saturation: 0.8, brightness: 1.0)))
    }

    private func move(_ id: UUID, by offset: Int) {
        guard let i = blobs.firstIndex(where: { $0.id == id }) else { return }
        let j = i + offset
        guard blobs.indices.contains(j) else { return }
        blobs.swapAt(i, j)
    }

    private func delete(_ id: UUID) {
        guard blobs.count > 1 else { return }
        blobs.removeAll { $0.id == id }
    }

    private func reset() {
        speed = 0.5; grain = 0.4; zoom = 0.5
        saturation = 1.0; softness = 1.0; warp = 1.0
        aberration = 0; vignette = 0; hueShift = 0
        darkBackground = false
        blobs = Self.defaultBlobs
    }

    // MARK: - Helpers

    private static func rgba(_ color: Color) -> (Float, Float, Float, Float) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Float(r), Float(g), Float(b), Float(a))
    }

    private func sliderRow(_ label: String,
                           _ value: Binding<Float>,
                           range: ClosedRange<Float> = 0...1) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                Slider(value: value, in: range)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FluidGradientView()
    }
}
