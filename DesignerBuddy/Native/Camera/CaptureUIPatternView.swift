import SwiftUI

// MARK: - Capture UI Pattern View

struct CaptureUIPatternView: View {
    @State private var layout: CaptureLayout = .standard
    @State private var showTopBar = true
    @State private var showModeStrip = true
    @State private var showGrid = false
    @State private var showBrackets = true
    @State private var shutterStyle: ShutterStyle = .circle

    private let canvasScale: CGFloat = 0.38

    var body: some View {
        List {
            Section("Pattern") {
                PresetChipRow(
                    chips: CaptureLayout.allCases.map { option in
                        PresetChip(name: option.rawValue, detail: option.note)
                    },
                    selectedID: layoutSelection
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Chrome") {
                Toggle("Top status bar", isOn: $showTopBar)
                    .disabled(layout == .minimalScan)
                Toggle("Mode strip", isOn: $showModeStrip)
                    .disabled(layout != .bottomStrip)
                Toggle("Grid overlay", isOn: $showGrid)
                Toggle("Corner brackets & crosshair", isOn: $showBrackets)
                    .disabled(layout != .minimalScan)
            }

            Section("Shutter") {
                Picker("Shutter style", selection: $shutterStyle) {
                    ForEach(ShutterStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .pinnedPreview {
            VStack(spacing: 8) {
                PhoneFrame {
                    selectedPattern
                }
                .scaleEffect(canvasScale)
                .frame(width: 280 * canvasScale, height: 560 * canvasScale)

                Text(layout.caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .animation(.spring(duration: 0.3), value: canvasState)
        }
        .navigationTitle("Capture UI Patterns")
    }

    @ViewBuilder
    private var selectedPattern: some View {
        switch layout {
        case .standard:
            StandardCenteredPattern(showTopBar: showTopBar, showGrid: showGrid, shutterStyle: shutterStyle)
        case .bottomStrip:
            BottomControlStripPattern(showTopBar: showTopBar, showModeStrip: showModeStrip, showGrid: showGrid, shutterStyle: shutterStyle)
        case .minimalScan:
            MinimalScanPattern(showGrid: showGrid, showBrackets: showBrackets, shutterStyle: shutterStyle)
        }
    }

    private var canvasState: [AnyHashable] {
        [layout, showTopBar, showModeStrip, showGrid, showBrackets, shutterStyle]
    }

    private var layoutSelection: Binding<String?> {
        Binding(
            get: { layout.rawValue },
            set: { name in
                guard let name, let option = CaptureLayout(rawValue: name) else { return }
                layout = option
            }
        )
    }
}

// MARK: - Capture Layout

private enum CaptureLayout: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case bottomStrip = "Bottom strip"
    case minimalScan = "Minimal scan"

    var id: Self { self }

    var caption: String {
        switch self {
        case .standard:    return "Standard centered shutter"
        case .bottomStrip: return "Bottom-docked control strip"
        case .minimalScan: return "Minimal / Scan mode"
        }
    }

    var note: String {
        switch self {
        case .standard:    return "Default camera app layout. Maximizes viewfinder real estate with symmetrical controls."
        case .bottomStrip: return "Used when mode-switching (Photo/Video/Slow-Mo) is a primary interaction. Extra vertical space for the strip."
        case .minimalScan: return "Document scanning and QR/barcode apps. Removes chrome to focus attention on the target subject."
        }
    }
}

// MARK: - Shutter Style

enum ShutterStyle: String, CaseIterable, Identifiable {
    case circle = "Circle"
    case roundedSquare = "Rounded square"

    var id: Self { self }
}

private struct ShutterButton: View {
    var style: ShutterStyle = .circle

    var body: some View {
        switch style {
        case .circle:
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 62, height: 62)
                Circle()
                    .fill(.white)
                    .frame(width: 52, height: 52)
            }
        case .roundedSquare:
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 62, height: 62)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .frame(width: 52, height: 52)
            }
        }
    }
}

// MARK: - Grid Overlay

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                for i in 1..<3 {
                    let x = w * CGFloat(i) / 3
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: h))
                    let y = h * CGFloat(i) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        }
    }
}

// MARK: - Phone Frame

struct PhoneFrame<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 44)
            .fill(Color.black)
            .frame(width: 280, height: 560)
            .overlay(
                RoundedRectangle(cornerRadius: 44)
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1.5)
            )
            .overlay(
                content
                    .clipShape(RoundedRectangle(cornerRadius: 44))
            )
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Pattern 1: Standard Centered

struct StandardCenteredPattern: View {
    var showTopBar: Bool = true
    var showGrid: Bool = false
    var shutterStyle: ShutterStyle = .circle

    var body: some View {
        VStack(spacing: 0) {
            // Top strip
            if showTopBar {
                HStack {
                    Image(systemName: "bolt.slash")
                    Spacer()
                    Image(systemName: "timer")
                    Spacer()
                    Image(systemName: "ellipsis")
                }
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
            }

            // Viewfinder
            Rectangle()
                .fill(Color(white: 0.15))
                .frame(maxHeight: .infinity)
                .overlay {
                    if showGrid {
                        GridOverlay()
                    }
                }

            // Bottom strip
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)

                Spacer()

                // Shutter
                ShutterButton(style: shutterStyle)

                Spacer()

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.3))
                    .frame(width: 38, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Pattern 2: Bottom Control Strip

struct BottomControlStripPattern: View {
    var showTopBar: Bool = true
    var showModeStrip: Bool = true
    var showGrid: Bool = false
    var shutterStyle: ShutterStyle = .circle

    var body: some View {
        VStack(spacing: 0) {
            // Minimal top bar
            if showTopBar {
                HStack {
                    Image(systemName: "xmark")
                    Spacer()
                    Image(systemName: "bolt.slash")
                }
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
            }

            // Viewfinder
            Rectangle()
                .fill(Color(white: 0.15))
                .frame(maxHeight: .infinity)
                .overlay {
                    if showGrid {
                        GridOverlay()
                    }
                }

            // Docked bottom strip
            VStack(spacing: 14) {
                // Mode selector
                if showModeStrip {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(["Slo-Mo", "Video", "Photo", "Portrait", "Pano"], id: \.self) { mode in
                                Text(mode)
                                    .font(.caption.weight(mode == "Photo" ? .bold : .regular))
                                    .foregroundStyle(mode == "Photo" ? Color.yellow : .white)
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                }

                // Controls row
                HStack {
                    Image(systemName: "rectangle.portrait.rotate")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    Spacer()

                    ShutterButton(style: shutterStyle)

                    Spacer()

                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28)
            }
            .padding(.vertical, 14)
            .frame(height: showModeStrip ? 100 : 90)
            .background(Color(white: 0.08))
        }
    }
}

// MARK: - Pattern 3: Minimal / Scan

struct MinimalScanPattern: View {
    var showGrid: Bool = false
    var showBrackets: Bool = true
    var shutterStyle: ShutterStyle = .circle

    var body: some View {
        ZStack {
            // Viewfinder background
            Color(white: 0.12)

            if showGrid {
                GridOverlay()
            }

            if showBrackets {
                // Corner brackets
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let inset: CGFloat = 48
                    let armLen: CGFloat = 24
                    let thickness: CGFloat = 3

                    ZStack {
                        // Top-left
                        CornerBracket(armLength: armLen, thickness: thickness)
                            .fill(.white)
                            .position(x: inset, y: inset)

                        // Top-right
                        CornerBracket(armLength: armLen, thickness: thickness)
                            .fill(.white)
                            .rotationEffect(.degrees(90))
                            .position(x: w - inset, y: inset)

                        // Bottom-left
                        CornerBracket(armLength: armLen, thickness: thickness)
                            .fill(.white)
                            .rotationEffect(.degrees(-90))
                            .position(x: inset, y: h - inset)

                        // Bottom-right
                        CornerBracket(armLength: armLen, thickness: thickness)
                            .fill(.white)
                            .rotationEffect(.degrees(180))
                            .position(x: w - inset, y: h - inset)
                    }
                }

                // Crosshair
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 20, height: 1)
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1, height: 20)
                }
            }

            // Single centered shutter button at bottom
            VStack {
                Spacer()
                ShutterButton(style: shutterStyle)
                    .padding(.bottom, 36)
            }
        }
    }
}

// MARK: - Corner Bracket Shape

struct CornerBracket: Shape {
    var armLength: CGFloat
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corner = CGPoint(x: rect.midX - armLength / 2, y: rect.midY - armLength / 2)
        // Horizontal arm going right
        path.move(to: CGPoint(x: corner.x + armLength, y: corner.y))
        path.addLine(to: corner)
        // Vertical arm going down
        path.addLine(to: CGPoint(x: corner.x, y: corner.y + armLength))
        return path.strokedPath(StrokeStyle(lineWidth: thickness, lineCap: .round))
    }
}

// Render corner bracket as stroked lines
struct CornerBracketView: View {
    var armLength: CGFloat = 24
    var color: Color = .white

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: armLength, height: 3)
            Rectangle()
                .fill(color)
                .frame(width: 3, height: armLength)
        }
    }
}

#Preview {
    NavigationStack {
        CaptureUIPatternView()
    }
}
