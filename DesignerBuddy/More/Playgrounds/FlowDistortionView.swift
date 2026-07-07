import PhotosUI
import SwiftUI
import UIKit

// Flow-distortion playground ported from Koshimizu-Takehito's my-toybox, extended
// with a custom photo source, adjustable step count / speed / aberration / tiling.
// A curl-noise flow field advects the image via a Metal layerEffect (flowDistortion
// in SDFShaders.metal), with chromatic aberration.

struct FlowDistortionView: View {
    private let startDate = Date()

    @State private var distortionStrength: Double = 0.021
    @State private var damping: Double = 0.95
    @State private var noiseScale: Double = 2.0
    @State private var speed: Double = 1.0
    @State private var steps: Double = 5
    @State private var aberration: Double = 0.01
    @State private var tiles: Double = 3

    @State private var photoItem: PhotosPickerItem?
    @State private var uiImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince(startDate) * speed
                    sourceImage
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .layerEffect(shader(time: time), maxSampleOffset: .zero)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                controls

                Text("A curl-noise flow field advects an image via a Metal `layerEffect`, with RGB "
                     + "channels split for chromatic aberration. Pick your own photo, and tune the "
                     + "flow strength, damping, noise, step count, speed, aberration and tiling. "
                     + "From my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .animation(.default, value: distortionStrength + damping + noiseScale + speed + steps + aberration + tiles)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flow Distortion")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    uiImage = image
                }
            }
        }
    }

    private var sourceImage: Image {
        if let uiImage { return Image(uiImage: uiImage) }
        return Image("PreviewBackground")
    }

    private var controls: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Image").frame(width: 96, alignment: .leading)
                Spacer()
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(uiImage == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                }
                if uiImage != nil {
                    Button {
                        uiImage = nil; photoItem = nil
                    } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            divider
            row("Strength",    $distortionStrength, 0.01...0.03, String(format: "%.3f", distortionStrength))
            divider
            row("Damping",     $damping,            0.10...1.00, String(format: "%.2f", damping))
            divider
            row("Noise Scale", $noiseScale,         1.0...3.0,   String(format: "%.2f", noiseScale))
            divider
            row("Speed",       $speed,              0.2...3.0,   String(format: "%.2f", speed))
            divider
            row("Flow Steps",  $steps,              1...12,      "\(Int(steps.rounded()))", step: 1)
            divider
            row("Aberration",  $aberration,         0...0.05,    String(format: "%.3f", aberration))
            divider
            row("Tiles",       $tiles,              1...6,       "\(Int(tiles.rounded()))", step: 1)
            divider
            Button(role: .destructive, action: reset) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reset() {
        distortionStrength = 0.021; damping = 0.95; noiseScale = 2.0
        speed = 1.0; steps = 5; aberration = 0.01; tiles = 3
    }

    private func row(_ label: String, _ value: Binding<Double>,
                     _ range: ClosedRange<Double>, _ text: String, step: Double = 0) -> some View {
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
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var divider: some View { Divider().padding(.leading, 16) }

    private func shader(time: TimeInterval) -> Shader {
        ShaderLibrary.flowDistortion(
            .float(Float(time)),
            .float(Float(distortionStrength)),
            .float(Float(damping)),
            .float(Float(noiseScale)),
            .float(Float(steps.rounded())),
            .float(Float(aberration)),
            .float(Float(tiles.rounded())),
            .boundingRect
        )
    }
}

// MARK: - Preview

#Preview { NavigationStack { FlowDistortionView() } }
