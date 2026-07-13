import SwiftUI

// Compact preset/reference selector: capsule chips in a full-bleed horizontal
// scroller. The selected chip grows an info button that pops the preset's
// detail text and optional code hint in a popover.
//
// Drop directly into a List and pair with:
//   .listRowInsets(EdgeInsets())
//   .listRowBackground(Color.clear)
//   .listRowSeparator(.hidden)
// so the scroller bleeds past the grouped card instead of clipping at it.

struct PresetChip: Identifiable, Equatable {
    let name: String
    let detail: String
    let code: String?
    var id: String { name }

    init(name: String, detail: String, code: String? = nil) {
        self.name = name
        self.detail = detail
        self.code = code
    }
}

struct PresetChipRow: View {
    let chips: [PresetChip]
    @Binding var selectedID: String?
    var onApply: (PresetChip) -> Void = { _ in }

    @State private var infoID: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    chipView(chip)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private func chipView(_ chip: PresetChip) -> some View {
        let isSelected = selectedID == chip.id
        return HStack(spacing: 5) {
            Text(chip.name)
                .font(.subheadline.weight(.medium))
            if isSelected {
                Button {
                    infoID = chip.id
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .popover(isPresented: infoBinding(for: chip), arrowEdge: .top) {
                    infoCard(chip)
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            isSelected ? AnyShapeStyle(.tint.opacity(0.15)) : AnyShapeStyle(Color(.tertiarySystemFill)),
            in: Capsule()
        )
        .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.spring(duration: 0.3)) {
                selectedID = chip.id
            }
            onApply(chip)
        }
        .animation(.spring(duration: 0.25), value: selectedID)
    }

    private func infoBinding(for chip: PresetChip) -> Binding<Bool> {
        Binding(
            get: { infoID == chip.id },
            set: { if !$0 { infoID = nil } }
        )
    }

    private func infoCard(_ chip: PresetChip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chip.name).font(.headline)
            Text(chip.detail).font(.caption).foregroundStyle(.secondary)
            if let code = chip.code {
                Text(code)
                    .font(.mono(.caption2))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(14)
        .frame(width: 260, alignment: .leading)
    }
}

#Preview {
    struct ChipsPreview: View {
        @State private var selected: String? = "Medium"
        var body: some View {
            List {
                Section("Presets") {
                    PresetChipRow(
                        chips: [
                            PresetChip(name: "None", detail: "Flat design, no elevation", code: "radius 0"),
                            PresetChip(name: "Medium", detail: "Dropdowns, menus", code: "radius 8, y 4"),
                            PresetChip(name: "Deep", detail: "High contrast, marketing", code: "radius 40, y 20"),
                        ],
                        selectedID: $selected
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
    return ChipsPreview()
}
