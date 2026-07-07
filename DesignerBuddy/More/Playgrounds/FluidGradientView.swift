import SwiftUI
import UIKit

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
    @State private var contrast:   Float = 1.0
    @State private var blobCount:  Float = 2
    @State private var colorA = Color(red: 1.0,  green: 0.5, blue: 0.0)
    @State private var colorB = Color(red: 0.55, green: 0.2, blue: 0.95)
    @State private var darkBackground = false
    @State private var isPaused = false

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
            let a = Self.rgb(colorA)
            let b = Self.rgb(colorB)
            let bg: (Float, Float, Float) = darkBackground ? (0.05, 0.05, 0.06) : (0.90, 0.90, 0.90)
            GeometryReader { geo in
                Color.black
                    .colorEffect(ShaderLibrary.chromaGradientArt(
                        .float2(geo.size),
                        .float(t * (speed * 2)),
                        .float(grain * 0.2),
                        .float(0.5 + zoom),
                        .float3(a.0, a.1, a.2),
                        .float3(b.0, b.1, b.2),
                        .float3(bg.0, bg.1, bg.2),
                        .float(saturation),
                        .float(softness),
                        .float(warp),
                        .float(blobCount.rounded()),
                        .float(contrast)
                    ))
            }
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            row {
                ColorPicker("Color A", selection: $colorA, supportsOpacity: false)
            }
            divider
            row {
                ColorPicker("Color B", selection: $colorB, supportsOpacity: false)
            }
            divider
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
            sliderRow("Contrast",   $contrast,   range: 0.5...2)
            divider
            row {
                HStack(spacing: 12) {
                    Text("Blobs").frame(width: 96, alignment: .leading)
                    Slider(value: $blobCount, in: 1...4, step: 1)
                    Text("\(Int(blobCount.rounded()))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 20, alignment: .trailing)
                }
            }
            divider
            row {
                HStack(spacing: 16) {
                    Button {
                        isPaused.toggle()
                    } label: {
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

    private var caption: some View {
        Text("A generative Metal shader: soft blobs warped by simplex noise over a grainy field. "
             + "Colours, background, saturation, blob softness/warp/contrast and count are all "
             + "tunable. Ports iShader's ChromaGradients (ShaderToy mtKfDG).")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Actions

    private func reset() {
        speed = 0.5; grain = 0.4; zoom = 0.5
        saturation = 1.0; softness = 1.0; warp = 1.0; contrast = 1.0
        blobCount = 2
        colorA = Color(red: 1.0,  green: 0.5, blue: 0.0)
        colorB = Color(red: 0.55, green: 0.2, blue: 0.95)
        darkBackground = false
    }

    // MARK: - Helpers

    private static func rgb(_ color: Color) -> (Float, Float, Float) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Float(r), Float(g), Float(b))
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
