import SwiftUI

struct SpacingView: View {
    private let spacingTokens: [(name: String, value: CGFloat)] = [
        ("2 — hairline", 2),
        ("4 — xs",       4),
        ("8 — sm",       8),
        ("12 — md-",     12),
        ("16 — md",      16),
        ("20 — md+",     20),
        ("24 — lg",      24),
        ("32 — xl",      32),
        ("40 — 2xl",     40),
        ("48 — 3xl",     48),
        ("64 — 4xl",     64),
    ]

    var body: some View {
        List {
            // MARK: Spacing scale
            Section("Spacing Scale") {
                ForEach(spacingTokens, id: \.name) { token in
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(.tint)
                            .frame(width: token.value, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(token.name)
                                .font(.mono(.subheadline))
                            Text("\(Int(token.value))pt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            // MARK: iOS standard margins
            Section {
                iOSMarginsCard()
                VStack(spacing: 0) {
                    MarginRow(name: "Layout Margin (leading/trailing)", value: 16)
                    Divider()
                    MarginRow(name: "List Row Inset",                   value: 16)
                    Divider()
                    MarginRow(name: "Section Header Bottom",            value: 8)
                    Divider()
                    MarginRow(name: "List Row Vertical Padding",        value: 11)
                    Divider()
                    MarginRow(name: "Nav Bar Large Title Height",       value: 52)
                    Divider()
                    MarginRow(name: "Tab Bar Height",                   value: 49)
                    Divider()
                    MarginRow(name: "Status Bar Height (approx)",       value: 59)
                }
            } header: {
                Text("iOS Standard Margins")
            } footer: {
                Text("The mock card above shows a title, body, and button inset at the standard 16pt horizontal margin.")
            }

            // MARK: Touch targets
            Section("Touch Targets") {
                TouchTargetRow(name: "Minimum tap target",    size: CGSize(width: 44, height: 44))
                TouchTargetRow(name: "Comfortable tap target", size: CGSize(width: 48, height: 48))
                TouchTargetRow(name: "Large tap target",       size: CGSize(width: 56, height: 56))
            }

            // MARK: Stack alignment
            Section("Stack Alignment") {
                StackAlignmentGrid()
            }

            // MARK: Frame behavior
            Section("Frame Behavior") {
                FrameDemo()
            }

            // MARK: Padding
            Section("Padding") {
                PaddingDemo()
            }
        }
        .navigationTitle("Spacing & Layout")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Shared sub-views

struct MarginRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text("\(Int(value))pt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

// Mock card showing 16pt margins in context
private struct iOSMarginsCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
            // margin guides
            GeometryReader { geo in
                let m: CGFloat = 16
                HStack(spacing: 0) {
                    Rectangle().fill(Color.accentColor.opacity(0.15)).frame(width: m)
                    Spacer()
                    Rectangle().fill(Color.accentColor.opacity(0.15)).frame(width: m)
                }
                // margin labels
                Text("16pt")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .position(x: m / 2, y: geo.size.height / 2)
                Text("16pt")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .position(x: geo.size.width - m / 2, y: geo.size.height / 2)
            }
            // content inset at 16pt margin
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("Body text sits at the standard 16pt layout margin — matching List row insets and scenePadding.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Primary Action") {}
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(height: 130)
        .padding(.vertical, 4)
    }
}

struct TouchTargetRow: View {
    let name: String
    let size: CGSize

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(.tint, lineWidth: 1.5)
                .frame(width: min(size.width, 56), height: min(size.height, 56))
                .overlay(
                    Text("\(Int(size.width))×\(Int(size.height))")
                        .font(.system(size: 8))
                        .foregroundStyle(.tint)
                )
            Text(name)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

struct StackAlignmentGrid: View {
    private let hAlignments: [(HorizontalAlignment, String)] = [
        (.leading, ".leading"), (.center, ".center"), (.trailing, ".trailing"),
    ]
    private let vAlignments: [(VerticalAlignment, String)] = [
        (.top, ".top"), (.center, ".center"), (.bottom, ".bottom"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("VStack — horizontal alignment")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(hAlignments, id: \.1) { alignment, label in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.quaternary)
                                .frame(height: 72)
                            VStack(alignment: alignment, spacing: 3) {
                                Capsule().fill(.tint).frame(width: 52, height: 5)
                                Capsule().fill(.tint.opacity(0.6)).frame(width: 36, height: 5)
                                Capsule().fill(.tint.opacity(0.3)).frame(width: 20, height: 5)
                            }
                            .frame(width: 60)
                        }
                        Text(label)
                            .font(.mono(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("HStack — vertical alignment")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(vAlignments, id: \.1) { alignment, label in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.quaternary)
                                .frame(height: 72)
                            HStack(alignment: alignment, spacing: 4) {
                                Capsule().fill(.tint).frame(width: 5, height: 40)
                                Capsule().fill(.tint.opacity(0.6)).frame(width: 5, height: 26)
                                Capsule().fill(.tint.opacity(0.3)).frame(width: 5, height: 16)
                            }
                        }
                        Text(label)
                            .font(.mono(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FrameDemo: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("maxWidth: .infinity")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            HStack(spacing: 8) {
                ForEach(["min", "ideal", "max"], id: \.self) { label in
                    Text(label)
                        .font(.mono(.caption2))
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PaddingDemo: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach([4.0, 8.0, 16.0, 24.0], id: \.self) { padding in
                VStack(spacing: 4) {
                    Text("Ag")
                        .font(.body)
                        .padding(padding)
                        .background(.tint.opacity(0.15))
                        .overlay(Rectangle().strokeBorder(.tint, lineWidth: 1))
                    Text("\(Int(padding))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        SpacingView()
    }
}
