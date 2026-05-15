import SwiftUI
import MapKit

struct MapBasicsView: View {
    @State private var styleIndex: Int = 0
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var showUserLocation: Bool = false

    private var mapStyle: MapStyle {
        switch styleIndex {
        case 1: return .imagery
        case 2: return .hybrid
        default: return .standard
        }
    }

    private let sfRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    private let nycRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    private let londonRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        Map(position: $position)
        .mapStyle(mapStyle)
        .mapControls {
            if showUserLocation {
                MapUserLocationButton()
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            MapBasicsControlCard(
                styleIndex: $styleIndex,
                showUserLocation: $showUserLocation,
                onSF: { position = .region(sfRegion) },
                onNYC: { position = .region(nycRegion) },
                onLondon: { position = .region(londonRegion) }
            )
        }
        .navigationTitle("Map Basics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MapBasicsControlCard: View {
    @Binding var styleIndex: Int
    @Binding var showUserLocation: Bool
    let onSF: () -> Void
    let onNYC: () -> Void
    let onLondon: () -> Void

    private var styleAPICaption: String {
        switch styleIndex {
        case 1: return ".mapStyle(.imagery)"
        case 2: return ".mapStyle(.hybrid)"
        default: return ".mapStyle(.standard)"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Map Style
            VStack(alignment: .leading, spacing: 8) {
                Label("Map Style", systemImage: "map")
                    .font(.subheadline.weight(.semibold))

                Picker("Map Style", selection: $styleIndex) {
                    Text("Standard").tag(0)
                    Text("Imagery").tag(1)
                    Text("Hybrid").tag(2)
                }
                .pickerStyle(.segmented)

                Text(styleAPICaption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }

            Divider()

            // Camera Presets
            VStack(alignment: .leading, spacing: 8) {
                Label("Camera Position", systemImage: "location.viewfinder")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 10) {
                    MapPresetButton(title: "SF", action: onSF)
                    MapPresetButton(title: "NYC", action: onNYC)
                    MapPresetButton(title: "London", action: onLondon)
                }

                Text("MapCameraPosition.region(MKCoordinateRegion(...))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }

            Divider()

            // User Location
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $showUserLocation) {
                    Label("Show My Location", systemImage: "location.fill")
                        .font(.subheadline.weight(.semibold))
                }

                Text(".mapControls { MapUserLocationButton() }")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)

                if showUserLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text("Location permission required — see Permissions section")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct MapPresetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationStack {
        MapBasicsView()
    }
}
