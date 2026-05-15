import SwiftUI
import MapKit

private let ggpRouteCoordinates: [CLLocationCoordinate2D] = [
    .init(latitude: 37.7694, longitude: -122.4862), // Panhandle entrance
    .init(latitude: 37.7712, longitude: -122.4938), // MLK Drive
    .init(latitude: 37.7699, longitude: -122.5010), // Crossover Drive
    .init(latitude: 37.7716, longitude: -122.5094), // Buffalo Paddock
    .init(latitude: 37.7708, longitude: -122.5107), // Chain of Lakes
]

private let circleCenter = CLLocationCoordinate2D(latitude: 37.7707, longitude: -122.4985)

private let ggpRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 37.770, longitude: -122.498),
    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
)

struct MapOverlaysView: View {
    @State private var strokeColor: Color = .blue
    @State private var lineWidth: Double = 4
    @State private var showCircle: Bool = true
    @State private var circleRadius: Double = 400
    @State private var position: MapCameraPosition = .region(ggpRegion)

    var body: some View {
        Map(position: $position) {
            MapPolyline(coordinates: ggpRouteCoordinates)
                .stroke(strokeColor, lineWidth: lineWidth)

            if showCircle {
                MapCircle(center: circleCenter, radius: circleRadius)
                    .foregroundStyle(.blue.opacity(0.15))
                    .stroke(.blue, lineWidth: 2)
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            MapOverlaysControlCard(
                strokeColor: $strokeColor,
                lineWidth: $lineWidth,
                showCircle: $showCircle,
                circleRadius: $circleRadius
            )
        }
        .navigationTitle("Map Overlays")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MapOverlaysControlCard: View {
    @Binding var strokeColor: Color
    @Binding var lineWidth: Double
    @Binding var showCircle: Bool
    @Binding var circleRadius: Double

    var body: some View {
        VStack(spacing: 16) {
            // Polyline section
            VStack(alignment: .leading, spacing: 10) {
                Label("MapPolyline", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.subheadline.weight(.semibold))

                HStack {
                    Text("Stroke Color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    ColorPicker("Stroke Color", selection: $strokeColor, supportsOpacity: false)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Line Width")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0fpt", lineWidth))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $lineWidth, in: 2...12, step: 1)
                        .tint(strokeColor)
                }

                // Caption uses lineWidth directly; color shown as a swatch since
                // Color doesn't have a reliable display name after ColorPicker changes.
                HStack(spacing: 4) {
                    Text("MapPolyline(coordinates: route)\n    .stroke(")
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strokeColor)
                        .frame(width: 14, height: 10)
                    Text(", lineWidth: \(Int(lineWidth)))")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fontDesign(.monospaced)
            }

            Divider()

            // Circle section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("MapCircle", systemImage: "circle.dashed")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Toggle("Show circle", isOn: $showCircle)
                        .labelsHidden()
                }

                if showCircle {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Radius")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0fm", circleRadius))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $circleRadius, in: 100...1000, step: 50)
                            .tint(.blue)
                    }

                    Text("MapCircle(center: center, radius: \(Int(circleRadius)))\n    .foregroundStyle(.blue.opacity(0.15))\n    .stroke(.blue, lineWidth: 2)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fontDesign(.monospaced)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        MapOverlaysView()
    }
}
