import SwiftUI

// MARK: - Capture UI Pattern View

struct CaptureUIPatternView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                patternCard(
                    title: "Standard Centered",
                    caption: "Default camera app layout. Maximizes viewfinder real estate with symmetrical controls.",
                    label: "Standard centered shutter"
                ) {
                    StandardCenteredPattern()
                }

                patternCard(
                    title: "Bottom Control Strip",
                    caption: "Used when mode-switching (Photo/Video/Slow-Mo) is a primary interaction. Extra vertical space for the strip.",
                    label: "Bottom-docked control strip"
                ) {
                    BottomControlStripPattern()
                }

                patternCard(
                    title: "Minimal / Scan",
                    caption: "Document scanning and QR/barcode apps. Removes chrome to focus attention on the target subject.",
                    label: "Minimal / Scan mode"
                ) {
                    MinimalScanPattern()
                }
            }
            .padding(20)
        }
        .navigationTitle("Capture UI Patterns")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Card Container

    @ViewBuilder
    private func patternCard<Content: View>(
        title: String,
        caption: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            PhoneFrame {
                content()
            }

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Text(caption)
                .font(.caption)
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .padding(.horizontal, 4)
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
    var body: some View {
        VStack(spacing: 0) {
            // Top strip
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

            // Viewfinder
            Rectangle()
                .fill(Color(white: 0.15))
                .frame(maxHeight: .infinity)

            // Bottom strip
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)

                Spacer()

                // Shutter
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 62, height: 62)
                    Circle()
                        .fill(.white)
                        .frame(width: 52, height: 52)
                }

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
    var body: some View {
        VStack(spacing: 0) {
            // Minimal top bar
            HStack {
                Image(systemName: "xmark")
                Spacer()
                Image(systemName: "bolt.slash")
            }
            .font(.system(size: 18))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)

            // Viewfinder
            Rectangle()
                .fill(Color(white: 0.15))
                .frame(maxHeight: .infinity)

            // Docked bottom strip
            VStack(spacing: 14) {
                // Mode selector
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

                // Controls row
                HStack {
                    Image(systemName: "rectangle.portrait.rotate")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                            .frame(width: 62, height: 62)
                        Circle()
                            .fill(.white)
                            .frame(width: 52, height: 52)
                    }

                    Spacer()

                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28)
            }
            .padding(.vertical, 14)
            .frame(height: 100)
            .background(Color(white: 0.08))
        }
    }
}

// MARK: - Pattern 3: Minimal / Scan

struct MinimalScanPattern: View {
    var body: some View {
        ZStack {
            // Viewfinder background
            Color(white: 0.12)

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
                        .position(x: inset, y: inset)

                    // Top-right
                    CornerBracket(armLength: armLen, thickness: thickness)
                        .rotationEffect(.degrees(90))
                        .position(x: w - inset, y: inset)

                    // Bottom-left
                    CornerBracket(armLength: armLen, thickness: thickness)
                        .rotationEffect(.degrees(-90))
                        .position(x: inset, y: h - inset)

                    // Bottom-right
                    CornerBracket(armLength: armLen, thickness: thickness)
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

            // Single centered shutter button at bottom
            VStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 62, height: 62)
                    Circle()
                        .fill(.white)
                        .frame(width: 52, height: 52)
                }
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
        // Horizontal arm going right
        path.move(to: CGPoint(x: -armLength / 2, y: 0))
        path.addLine(to: CGPoint(x: armLength / 2, y: 0))
        // Vertical arm going down
        path.move(to: CGPoint(x: 0, y: -armLength / 2))
        path.addLine(to: CGPoint(x: 0, y: armLength / 2))
        return path
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
