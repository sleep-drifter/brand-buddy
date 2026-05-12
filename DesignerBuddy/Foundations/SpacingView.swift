import SwiftUI

struct SpacingView: View {
    private let spacingTokens: [(name: String, value: CGFloat)] = [
        ("2 — hairline", 2),
        ("4 — xs", 4),
        ("8 — sm", 8),
        ("12 — md-", 12),
        ("16 — md", 16),
        ("20 — md+", 20),
        ("24 — lg", 24),
        ("32 — xl", 32),
        ("40 — 2xl", 40),
        ("48 — 3xl", 48),
        ("64 — 4xl", 64),
    ]

    var body: some View {
        List {
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

            Section("iOS Standard Margins") {
                MarginRow(name: "Layout Margin (leading/trailing)", value: 16)
                MarginRow(name: "List Row Inset", value: 16)
                MarginRow(name: "Section Header Bottom", value: 8)
                MarginRow(name: "List Row Vertical Padding", value: 11)
                MarginRow(name: "Nav Bar Large Title Height", value: 52)
                MarginRow(name: "Tab Bar Height", value: 49)
                MarginRow(name: "Status Bar Height (approx)", value: 59)
            }

            Section("Touch Targets") {
                TouchTargetRow(name: "Minimum tap target", size: CGSize(width: 44, height: 44))
                TouchTargetRow(name: "Comfortable tap target", size: CGSize(width: 48, height: 48))
                TouchTargetRow(name: "Large tap target", size: CGSize(width: 56, height: 56))
            }
        }
        .navigationTitle("Spacing & Grid")
        .navigationBarTitleDisplayMode(.large)
    }
}

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

#Preview {
    NavigationStack {
        SpacingView()
    }
}
