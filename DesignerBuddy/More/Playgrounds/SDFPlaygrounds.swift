import SwiftUI

// Signed-distance-field playgrounds ported from Koshimizu-Takehito's my-toybox
// (CircleSDF1 / CircleSDF2 / SmoothMin). Shaders live in SDFShaders.metal and are
// invoked via ShaderLibrary. Each view auto-animates time from a start date so the
// Float stays small and precise.

// MARK: - Shared preview scaffold

private struct SDFPreview<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .frame(height: 340)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
    }
}

private struct SDFCaption: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private func sdfSliderRow(_ label: String,
                          _ value: Binding<Double>,
                          range: ClosedRange<Double>,
                          valueText: String) -> some View {
    HStack(spacing: 12) {
        Text(label).frame(width: 110, alignment: .leading)
        Slider(value: value, in: range)
        Text(valueText)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 40, alignment: .trailing)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
}

// MARK: - Circle SDF 1

/// Two circles orbiting and fusing via a fixed smooth-minimum. No controls —
/// the classic metaball SDF demo.
struct CircleSDF1View: View {
    private let startDate = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDFPreview {
                    TimelineView(.animation) { tl in
                        let t = Float(tl.date.timeIntervalSince(startDate))
                        Rectangle()
                            .colorEffect(ShaderLibrary.circleSDF1(.boundingRect, .float(t)))
                    }
                }
                SDFCaption(text: "Two circles defined as signed distance fields, orbiting and "
                           + "blended with a smooth-minimum so they fuse where they meet. Inside "
                           + "the field is filled blue, outside white. From Koshimizu-Takehito\u{2019}s "
                           + "my-toybox (CircleSDF1).")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Circle SDF 1")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Circle SDF 2

/// Like SDF 1, but the smoothing factor doubles as the circle radius and the
/// interior is banded with iso-lines. `Smoothing` (k) is adjustable.
struct CircleSDF2View: View {
    private let startDate = Date()
    @State private var k: Double = 0.36

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDFPreview {
                    TimelineView(.animation) { tl in
                        let t = Float(tl.date.timeIntervalSince(startDate))
                        Rectangle()
                            .colorEffect(ShaderLibrary.circleSDF2(.boundingRect,
                                                                  .float(t),
                                                                  .float(Float(k))))
                    }
                }
                VStack(spacing: 0) {
                    sdfSliderRow("Smoothing", $k, range: 0.05...0.72,
                                 valueText: String(format: "%.2f", k))
                }
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                SDFCaption(text: "The same orbiting SDF circles, but the smooth-minimum factor "
                           + "\u{201C}k\u{201D} also sets the radius, and the interior is drawn "
                           + "with distance iso-lines. Raise Smoothing to watch the blobs swell and "
                           + "merge. From my-toybox (CircleSDF2).")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Circle SDF 2")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Smooth Min 2D

/// Visualizes the smooth-minimum blend field itself: interior tinted by each
/// circle's distance, exterior by the merged field. `Smoothing` (k) adjustable.
struct SmoothMin2DView: View {
    private let startDate = Date()
    @State private var k: Double = 0.8

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDFPreview {
                    TimelineView(.animation) { tl in
                        let t = Float(tl.date.timeIntervalSince(startDate))
                        Rectangle()
                            .colorEffect(ShaderLibrary.smoothMin2D(.boundingRect,
                                                                   .float(t),
                                                                   .float(Float(k))))
                    }
                }
                VStack(spacing: 0) {
                    sdfSliderRow("Smoothing", $k, range: 0.0...1.0,
                                 valueText: String(format: "%.2f", k))
                }
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                SDFCaption(text: "A visualization of the smooth-minimum operator: the two circles\u{2019} "
                           + "distance fields are tinted magenta and cyan, blended by the merged field "
                           + "with k controlling how gently they join. Turn Smoothing down for a hard "
                           + "union, up for a liquid merge. From my-toybox (SmoothMin).")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Smooth Min 2D")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("Circle SDF 1") { NavigationStack { CircleSDF1View() } }
#Preview("Circle SDF 2") { NavigationStack { CircleSDF2View() } }
#Preview("Smooth Min 2D") { NavigationStack { SmoothMin2DView() } }
