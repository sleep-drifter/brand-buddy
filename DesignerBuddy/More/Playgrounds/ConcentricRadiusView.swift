import SwiftUI

struct ConcentricRadiusView: View {
    @State private var outerRadius: CGFloat = 32
    @State private var padding: CGFloat = 12
    @State private var selectedExample: String?

    var innerConcentric: CGFloat { max(outerRadius - padding, 0) }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text("inner radius = outer radius − padding")
                        .font(.mono(.subheadline))
                        .multilineTextAlignment(.center)
                    Text("\(Int(innerConcentric)) = \(Int(outerRadius)) − \(Int(padding))")
                        .font(.mono(.title3))
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: innerConcentric)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                LabeledContent("Outer Radius (R): \(Int(outerRadius))pt") {
                    Slider(value: $outerRadius, in: 8...56)
                }
                LabeledContent("Padding (p): \(Int(padding))pt") {
                    Slider(value: $padding, in: 4...32)
                }
            }

            Section("Why it matters") {
                Text("When two rounded rectangles share the same radius, their curves don't follow the same center — they look like separate shapes placed near each other.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Subtracting the padding aligns both curves to the same focal point, so the inner shape feels like it belongs inside the outer one.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Real examples") {
                PresetChipRow(
                    chips: ConcentricExample.all.map { ex in
                        PresetChip(
                            name: ex.name,
                            detail: ex.detail,
                            code: "outer: \(Int(ex.outer)), padding: \(Int(ex.padding))"
                        )
                    },
                    selectedID: $selectedExample
                ) { chip in
                    guard let ex = ConcentricExample.all.first(where: { $0.name == chip.name }) else { return }
                    withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                        outerRadius = ex.outer
                        padding = ex.padding
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .pinnedPreview(entry: "Concentric Radius") {
            HStack(spacing: 20) {
                VStack(spacing: 10) {
                    concentricCard(innerRadius: innerConcentric, label: "Concentric\n(R − p)")
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .padding(8)
                        }
                    Text("inner = \(Int(innerConcentric))pt")
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    concentricCard(innerRadius: outerRadius, label: "Naive\n(same R)")
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .padding(8)
                        }
                    Text("inner = \(Int(outerRadius))pt")
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Concentric Radius")
    }

    @ViewBuilder
    func concentricCard(innerRadius: CGFloat, label: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 150, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .strokeBorder(.separator, lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(.tint.opacity(0.15))
                .frame(
                    width: 150 - padding * 2,
                    height: 150 - padding * 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                        .strokeBorder(.tint, lineWidth: 1.5)
                )
                .overlay(
                    Text(label)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.tint)
                )
        }
        .animation(.spring(duration: 0.35, bounce: 0.1), value: outerRadius)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: padding)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: innerRadius)
    }
}

struct ConcentricExample: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let outer: CGFloat
    let padding: CGFloat

    static let all: [ConcentricExample] = [
        ConcentricExample(name: "App icon badge", detail: "Icon 27pt, badge 8pt inset → badge at 19pt", outer: 27, padding: 8),
        ConcentricExample(name: "Card with chip", detail: "Card 20pt, chip 8pt inset → chip at 12pt", outer: 20, padding: 8),
        ConcentricExample(name: "Sheet row", detail: "Sheet 32pt, row 12pt inset → row at 20pt", outer: 32, padding: 12),
        ConcentricExample(name: "Widget inner", detail: "Widget 24pt, content 6pt inset → content at 18pt", outer: 24, padding: 6),
        ConcentricExample(name: "Tight inset", detail: "Container 16pt, 4pt padding → inner at 12pt", outer: 16, padding: 4),
    ]
}

#Preview {
    NavigationStack {
        ConcentricRadiusView()
    }
    .environmentObject(PinsStore())
}
