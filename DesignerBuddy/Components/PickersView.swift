import SwiftUI

struct PickersView: View {
    private enum StyleChoice: String, CaseIterable {
        case automatic, menu, segmented, wheel, inline

        var note: String {
            switch self {
            case .automatic: return "Context-dependent — resolves to a menu in most containers."
            case .menu:      return "Compact popup button; the list and form default. Best for 5+ options."
            case .segmented: return "All options visible at once. Use for 2–4 short, fixed choices."
            case .wheel:     return "Scrolling drum in a fixed-height area. Good for long ordered sets."
            case .inline:    return "Options render as checkmarked rows in the enclosing container."
            }
        }
    }

    @State private var selection = 1
    @State private var style: StyleChoice = .automatic
    @State private var optionCount = 3.0
    @State private var tint = Color.blue

    private let selectionFeedback = UISelectionFeedbackGenerator()

    private var optionTotal: Int { Int(optionCount) }

    var body: some View {
        List {
            Section("Controls") {
                LabeledContent("options: \(optionTotal)") {
                    Slider(value: $optionCount, in: 2...6, step: 1)
                }

                ColorPicker("Tint", selection: $tint, supportsOpacity: false)
            }

            Section("Styles") {
                PresetChipRow(
                    chips: StyleChoice.allCases.map { s in
                        PresetChip(name: ".\(s.rawValue)", detail: s.note, code: ".pickerStyle(.\(s.rawValue))")
                    },
                    selectedID: styleSelection
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .pinnedPreview(entry: "Pickers") {
            VStack(spacing: 10) {
                VStack {
                    Spacer(minLength: 0)
                    specimen
                        .tint(tint)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("selected: Option \(selection)")
                    .font(.mono(.callout))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.12), in: Capsule())
            }
            .animation(.spring(duration: 0.3), value: style)
        }
        .navigationTitle("Pickers")
        .onAppear { selectionFeedback.prepare() }
        .onChange(of: selection) { _, _ in selectionFeedback.selectionChanged() }
        .onChange(of: optionCount) { _, _ in
            selection = min(selection, optionTotal)
        }
    }

    private var styleSelection: Binding<String?> {
        Binding(
            get: { ".\(style.rawValue)" },
            set: { name in
                guard let name, let s = StyleChoice.allCases.first(where: { ".\($0.rawValue)" == name }) else { return }
                style = s
            }
        )
    }

    @ViewBuilder private var specimen: some View {
        let picker = Picker("Options", selection: $selection) {
            ForEach(1...optionTotal, id: \.self) { i in
                Text("Option \(i)").tag(i)
            }
        }
        switch style {
        case .automatic:
            picker.pickerStyle(.automatic)
        case .menu:
            picker.pickerStyle(.menu)
        case .segmented:
            picker.pickerStyle(.segmented)
        case .wheel:
            picker.pickerStyle(.wheel)
                .frame(height: 160)
        case .inline:
            picker.pickerStyle(.inline)
        }
    }
}

struct SegmentedControlsView: View {
    @State private var selected = 0
    @State private var selected2 = "Map"
    @State private var selected3 = 1

    var body: some View {
        List {
            Section("Text Segments") {
                Picker("View", selection: $selected2) {
                    Text("Map").tag("Map")
                    Text("Transit").tag("Transit")
                    Text("Satellite").tag("Satellite")
                }
                .pickerStyle(.segmented)
            }

            Section("With Icons") {
                Picker("Layout", selection: $selected) {
                    Image(systemName: "list.bullet").tag(0)
                    Image(systemName: "square.grid.2x2").tag(1)
                    Image(systemName: "rectangle.grid.1x2").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section("States") {
                Picker("Normal", selection: $selected3) {
                    Text("One").tag(1)
                    Text("Two").tag(2)
                    Text("Three").tag(3)
                }
                .pickerStyle(.segmented)

                Picker("Disabled", selection: .constant(1)) {
                    Text("One").tag(1)
                    Text("Two").tag(2)
                }
                .pickerStyle(.segmented)
                .disabled(true)
            }
        }
        .navigationTitle("Segmented Controls")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DateTimePickersView: View {
    private enum StyleChoice: String, CaseIterable {
        case compact, graphical, wheel

        var note: String {
            switch self {
            case .compact:   return "Label plus tappable capsules that expand a calendar or time popover. The iOS default."
            case .graphical: return "Full inline calendar with a time field — the Calendar-app look."
            case .wheel:     return "Classic scrolling drums with a fixed footprint."
            }
        }
    }

    private enum ComponentsChoice: String, CaseIterable {
        case date = "Date"
        case time = "Time"
        case dateAndTime = "Date + Time"

        var components: DatePickerComponents {
            switch self {
            case .date:        return [.date]
            case .time:        return [.hourAndMinute]
            case .dateAndTime: return [.date, .hourAndMinute]
            }
        }

        var code: String {
            switch self {
            case .date:        return "[.date]"
            case .time:        return "[.hourAndMinute]"
            case .dateAndTime: return "[.date, .hourAndMinute]"
            }
        }
    }

    @State private var date = Date()
    @State private var style: StyleChoice = .compact
    @State private var componentsChoice: ComponentsChoice = .date

    private var generatedCode: String {
        "DatePicker(\"Select\", selection: $date,\n  displayedComponents: \(componentsChoice.code))\n.datePickerStyle(.\(style.rawValue))"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    VStack {
                        Spacer(minLength: 0)
                        specimen
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 340)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(generatedCode)
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(duration: 0.3), value: style)
                .animation(.spring(duration: 0.3), value: componentsChoice)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                Picker("Shows", selection: $componentsChoice) {
                    ForEach(ComponentsChoice.allCases, id: \.self) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .pickerStyle(.segmented)

                LabeledContent("Selected") {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Styles") {
                PresetChipRow(
                    chips: StyleChoice.allCases.map { s in
                        PresetChip(name: ".\(s.rawValue)", detail: s.note, code: ".datePickerStyle(.\(s.rawValue))")
                    },
                    selectedID: styleSelection
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Date & Time Pickers")
        .navigationBarTitleDisplayMode(.large)
    }

    private var styleSelection: Binding<String?> {
        Binding(
            get: { ".\(style.rawValue)" },
            set: { name in
                guard let name, let s = StyleChoice.allCases.first(where: { ".\($0.rawValue)" == name }) else { return }
                style = s
            }
        )
    }

    @ViewBuilder private var specimen: some View {
        let picker = DatePicker("Select", selection: $date, displayedComponents: componentsChoice.components)
        switch style {
        case .compact:
            picker.datePickerStyle(.compact)
        case .graphical:
            picker.datePickerStyle(.graphical)
        case .wheel:
            picker.datePickerStyle(.wheel)
                .labelsHidden()
        }
    }
}

struct ColorPickerView: View {
    @State private var color = Color.blue
    @State private var color2 = Color.red

    var body: some View {
        List {
            Section("Default") {
                ColorPicker("Pick a color", selection: $color)
            }
            Section("Without opacity") {
                ColorPicker("Solid color", selection: $color2, supportsOpacity: false)
            }
            Section("Preview") {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
                    .frame(height: 80)
            }
        }
        .navigationTitle("Color Picker")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        PickersView()
    }
    .environmentObject(PinsStore())
}
