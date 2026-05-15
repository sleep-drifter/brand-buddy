import SwiftUI
import MapKit

struct MapLandmark: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
}

let sfLandmarks: [MapLandmark] = [
    MapLandmark(
        name: "Golden Gate Bridge",
        subtitle: "Iconic suspension bridge",
        coordinate: .init(latitude: 37.8199, longitude: -122.4783),
        color: .orange
    ),
    MapLandmark(
        name: "Alcatraz Island",
        subtitle: "Historic federal penitentiary",
        coordinate: .init(latitude: 37.8267, longitude: -122.4230),
        color: .red
    ),
    MapLandmark(
        name: "Ferry Building",
        subtitle: "Marketplace & transit hub",
        coordinate: .init(latitude: 37.7956, longitude: -122.3935),
        color: .blue
    ),
    MapLandmark(
        name: "Coit Tower",
        subtitle: "Art Deco tower, 1933",
        coordinate: .init(latitude: 37.8024, longitude: -122.4058),
        color: .green
    ),
    MapLandmark(
        name: "Palace of Fine Arts",
        subtitle: "Neoclassical rotunda",
        coordinate: .init(latitude: 37.8029, longitude: -122.4484),
        color: .purple
    ),
]

struct MapAnnotationsView: View {
    @State private var useMarker: Bool = true
    @State private var selectedLandmark: MapLandmark?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8050, longitude: -122.4400),
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )
    )

    var body: some View {
        Map(position: $position) {
            ForEach(sfLandmarks) { landmark in
                if useMarker {
                    Marker(landmark.name, coordinate: landmark.coordinate)
                        .tint(landmark.color)
                } else {
                    Annotation(landmark.name, coordinate: landmark.coordinate) {
                        CustomAnnotationView(landmark: landmark) {
                            selectedLandmark = landmark
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let selected = selectedLandmark {
                    LandmarkDetailCard(landmark: selected) {
                        selectedLandmark = nil
                    }
                }
                AnnotationControlCard(useMarker: $useMarker) {
                    selectedLandmark = nil
                }
            }
        }
        .navigationTitle("Map Annotations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AnnotationControlCard: View {
    @Binding var useMarker: Bool
    let onStyleChange: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Annotation Style", systemImage: "mappin.and.ellipse")
                    .font(.subheadline.weight(.semibold))

                Picker("Annotation Style", selection: $useMarker) {
                    Text("Marker").tag(true)
                    Text("Annotation").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: useMarker) { _, _ in
                    onStyleChange()
                }

                Group {
                    if useMarker {
                        Text("Marker(landmark.name, coordinate:)\n    .tint(landmark.color)")
                    } else {
                        Text("Annotation(name, coordinate:) { CustomView() }\n    .annotationTitles(.hidden)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fontDesign(.monospaced)
            }

            if !useMarker {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text("Tap an annotation pin to see landmark details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct LandmarkDetailCard: View {
    let landmark: MapLandmark
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(landmark.color)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)

                Text(landmark.name)
                    .font(.headline)

                Spacer()

                Button("Dismiss", action: onDismiss)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            Text(landmark.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(format: "%.4f°, %.4f°", landmark.coordinate.latitude, landmark.coordinate.longitude))
                .font(.caption2)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        MapAnnotationsView()
    }
}
