import SwiftUI

struct PickersView: View {
    @State private var selection1 = "Option A"
    @State private var selection2 = "Option B"
    @State private var selection3 = "Option A"
    @State private var selection4 = "Option A"

    private let options = ["Option A", "Option B", "Option C", "Option D"]
    private let selectionFeedback = UISelectionFeedbackGenerator()

    var body: some View {
        List {
            Section("Automatic (context-dependent)") {
                Picker("Picker", selection: $selection1) {
                    ForEach(options, id: \.self) { Text($0) }
                }
            }

            Section("Segmented") {
                Picker("Segmented", selection: $selection2) {
                    ForEach(["Day", "Week", "Month"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Wheel") {
                Picker("Wheel", selection: $selection3) {
                    ForEach(options, id: \.self) { Text($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }

            Section("Inline") {
                Picker("Inline", selection: $selection4) {
                    ForEach(options, id: \.self) { Text($0) }
                }
                .pickerStyle(.inline)
            }

            Section("Menu (compact)") {
                Picker("Menu picker", selection: $selection1) {
                    ForEach(options, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
            }
        }
        .navigationTitle("Pickers")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { selectionFeedback.prepare() }
        .onChange(of: selection1) { _, _ in selectionFeedback.selectionChanged() }
        .onChange(of: selection2) { _, _ in selectionFeedback.selectionChanged() }
        .onChange(of: selection3) { _, _ in selectionFeedback.selectionChanged() }
        .onChange(of: selection4) { _, _ in selectionFeedback.selectionChanged() }
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
    @State private var date = Date()
    @State private var time = Date()
    @State private var dateTime = Date()

    var body: some View {
        List {
            Section("Date only") {
                DatePicker("Select date", selection: $date, displayedComponents: .date)
            }
            Section("Time only") {
                DatePicker("Select time", selection: $time, displayedComponents: .hourAndMinute)
            }
            Section("Date & Time") {
                DatePicker("Select", selection: $dateTime)
            }
            Section("Inline (calendar)") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            Section("Wheel") {
                DatePicker("Date", selection: $date)
                    .datePickerStyle(.wheel)
            }
        }
        .navigationTitle("Date & Time Pickers")
        .navigationBarTitleDisplayMode(.large)
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
}
