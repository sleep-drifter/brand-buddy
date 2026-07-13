import SwiftUI

struct SafeAreasView: View {
    @State private var selectedDevice: DeviceSpec = DeviceSpec.all[0]

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    phoneCanvas
                    Text("\(selectedDevice.name) — \(Int(selectedDevice.width))×\(Int(selectedDevice.height))pt @\(Int(selectedDevice.scale))x")
                        .font(.mono(.caption2))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Select Device") {
                Picker("Device", selection: $selectedDevice) {
                    ForEach(DeviceSpec.all) { device in
                        Text(device.name).tag(device)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Live Safe Area") {
                LiveSafeAreaView()
            }

            Section("Safe Area Insets — \(selectedDevice.name)") {
                DeviceSpecRow(label: "Top (status bar + notch/island)", value: selectedDevice.safeTop)
                DeviceSpecRow(label: "Bottom (home indicator)", value: selectedDevice.safeBottom)
                DeviceSpecRow(label: "Leading", value: selectedDevice.safeLeading)
                DeviceSpecRow(label: "Trailing", value: selectedDevice.safeTrailing)
            }

            Section("Screen Dimensions — \(selectedDevice.name)") {
                DeviceSpecRow(label: "Screen width", value: selectedDevice.width)
                DeviceSpecRow(label: "Screen height", value: selectedDevice.height)
                DeviceSpecRow(label: "Display corner radius", value: selectedDevice.screenRadius)
                DeviceSpecRow(label: "Scale factor", value: Int(selectedDevice.scale), unit: "×")
            }

            Section("Safe Area Concepts") {
                ForEach(SafeAreaConcept.all) { concept in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(concept.name).font(.subheadline).fontWeight(.medium)
                        Text(concept.description).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Safe Areas")
        .navigationBarTitleDisplayMode(.large)
    }

    private var phoneCanvas: some View {
        let phoneHeight: CGFloat = 320
        let pointScale = phoneHeight / selectedDevice.height
        let phoneWidth = selectedDevice.width * pointScale
        let cornerRadius = selectedDevice.screenRadius * pointScale
        let topBandHeight = selectedDevice.safeTop * pointScale
        let bottomBandHeight = selectedDevice.safeBottom * pointScale

        return VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.2))
                if selectedDevice.safeTop >= 59 {
                    Capsule()
                        .fill(.primary)
                        .frame(width: 44, height: 13)
                } else if selectedDevice.safeTop >= 44 {
                    UnevenRoundedRectangle(bottomLeadingRadius: 7, bottomTrailingRadius: 7, style: .continuous)
                        .fill(.primary)
                        .frame(width: 74, height: 10)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(height: topBandHeight)

            Text("top \(Int(selectedDevice.safeTop))pt")
                .font(.mono(.caption2))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer(minLength: 0)

            Text("bottom \(Int(selectedDevice.safeBottom))pt")
                .font(.mono(.caption2))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            ZStack {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.2))
                if selectedDevice.safeBottom > 0 {
                    Capsule()
                        .fill(.secondary)
                        .frame(width: 48, height: 4)
                }
            }
            .frame(height: bottomBandHeight)
        }
        .frame(width: phoneWidth, height: phoneHeight)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.separator, lineWidth: 1)
        )
        .animation(.spring(duration: 0.3), value: selectedDevice)
    }
}

struct LiveSafeAreaView: View {
    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            VStack(spacing: 8) {
                Text("Current device safe area insets:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    InsetBadge(label: "Top", value: insets.top)
                    InsetBadge(label: "Bottom", value: insets.bottom)
                    InsetBadge(label: "Leading", value: insets.leading)
                    InsetBadge(label: "Trailing", value: insets.trailing)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .frame(height: 80)
    }
}

struct InsetBadge: View {
    let label: String
    let value: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value))")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct DeviceSpecRow: View {
    let label: String
    let value: CGFloat
    var unit: String = "pt"

    init(label: String, value: CGFloat, unit: String = "pt") {
        self.label = label
        self.value = value
        self.unit = unit
    }

    init(label: String, value: Int, unit: String) {
        self.label = label
        self.value = CGFloat(value)
        self.unit = unit
    }

    var body: some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text("\(Int(value))\(unit)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.tint)
        }
    }
}

struct DeviceSpec: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let safeTop: CGFloat
    let safeBottom: CGFloat
    let safeLeading: CGFloat
    let safeTrailing: CGFloat
    // Display corner radius in points (0 = rectangular LCD)
    let screenRadius: CGFloat

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DeviceSpec, rhs: DeviceSpec) -> Bool { lhs.id == rhs.id }

    static let all: [DeviceSpec] = [
        DeviceSpec(name: "iPhone 16 Pro Max", width: 440, height: 956, scale: 3, safeTop: 62, safeBottom: 34, safeLeading: 0, safeTrailing: 0, screenRadius: 62),
        DeviceSpec(name: "iPhone 16 Pro", width: 402, height: 874, scale: 3, safeTop: 62, safeBottom: 34, safeLeading: 0, safeTrailing: 0, screenRadius: 62),
        DeviceSpec(name: "iPhone 16 Plus", width: 430, height: 932, scale: 3, safeTop: 59, safeBottom: 34, safeLeading: 0, safeTrailing: 0, screenRadius: 55),
        DeviceSpec(name: "iPhone 16", width: 393, height: 852, scale: 3, safeTop: 59, safeBottom: 34, safeLeading: 0, safeTrailing: 0, screenRadius: 55),
        DeviceSpec(name: "iPhone 15", width: 393, height: 852, scale: 3, safeTop: 59, safeBottom: 34, safeLeading: 0, safeTrailing: 0, screenRadius: 55),
        DeviceSpec(name: "iPhone SE (3rd gen)", width: 375, height: 667, scale: 2, safeTop: 20, safeBottom: 0, safeLeading: 0, safeTrailing: 0, screenRadius: 0),
        DeviceSpec(name: "iPhone 14", width: 390, height: 844, scale: 3, safeTop: 47, safeBottom: 34, safeLeading: 0, safeTrailing: 0, screenRadius: 47.33),
    ]
}

struct SafeAreaConcept: Identifiable {
    let id = UUID()
    let name: String
    let description: String

    static let all: [SafeAreaConcept] = [
        SafeAreaConcept(name: ".ignoresSafeArea(edges:)", description: "Extend content into safe areas — common for backgrounds, images, and gradients that should bleed to the screen edge."),
        SafeAreaConcept(name: ".safeAreaInset(edge:)", description: "Add persistent content above/below the safe area — e.g. a floating bottom action bar without obscuring scrollable content."),
        SafeAreaConcept(name: "GeometryReader + safeAreaInsets", description: "Read safe area insets programmatically to adapt layouts at runtime. Useful for custom bottom sheets or overlay positioning."),
        SafeAreaConcept(name: "Content safe area", description: "The area where interactive and readable content should live. Never place important content in the top status bar region or below the home indicator."),
    ]
}

#Preview {
    NavigationStack {
        SafeAreasView()
    }
}
