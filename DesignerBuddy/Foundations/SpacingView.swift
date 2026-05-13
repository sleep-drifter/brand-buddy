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
            Section("iOS Standard Margins") {
                MarginRow(name: "Layout Margin (leading/trailing)", value: 16)
                MarginRow(name: "List Row Inset",                   value: 16)
                MarginRow(name: "Section Header Bottom",            value: 8)
                MarginRow(name: "List Row Vertical Padding",        value: 11)
                MarginRow(name: "Nav Bar Large Title Height",       value: 52)
                MarginRow(name: "Tab Bar Height",                   value: 49)
                MarginRow(name: "Status Bar Height (approx)",       value: 59)
            }

            // MARK: Touch targets
            Section("Touch Targets") {
                TouchTargetRow(name: "Minimum tap target",    size: CGSize(width: 44, height: 44))
                TouchTargetRow(name: "Comfortable tap target", size: CGSize(width: 48, height: 48))
                TouchTargetRow(name: "Large tap target",       size: CGSize(width: 56, height: 56))
            }

            // MARK: Stack alignment
            Section("Stack Alignment") {
                StackAlignmentDemo()
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

struct StackAlignmentDemo: View {
    var body: some View {
        let alignments: [(HorizontalAlignment, String)] = [
            (.leading, "leading"), (.center, "center"), (.trailing, "trailing"),
        ]
        VStack(spacing: 16) {
            ForEach(alignments, id: \.1) { alignment, label in
                VStack(alignment: alignment, spacing: 4) {
                    Rectangle().fill(.tint.opacity(0.3)).frame(width: 180, height: 6).clipShape(Capsule())
                    Rectangle().fill(.tint.opacity(0.5)).frame(width: 120, height: 6).clipShape(Capsule())
                    Rectangle().fill(.tint).frame(width: 80, height: 6).clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Text(".\(label)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
            }
        }
        .padding(.vertical, 8)
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
