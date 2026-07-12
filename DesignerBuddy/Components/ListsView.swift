import SwiftUI

// MARK: - ListsView (#010 — inline mock cards for each list style)

struct ListsView: View {
    @State private var checked = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: Plain
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plain")
                            .font(.headline)
                        Text(".listStyle(.plain)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(["Row 1", "Row 2", "Row 3", "Row 4"], id: \.self) { label in
                                HStack {
                                    Text(label)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                    }

                    // MARK: Inset Grouped
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inset Grouped")
                            .font(.headline)
                        Text(".listStyle(.insetGrouped)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            ForEach(["Section A", "Section B"], id: \.self) { section in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(section)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 4)
                                    VStack(spacing: 0) {
                                        ForEach(1...3, id: \.self) { i in
                                            HStack {
                                                Text("Row \(i)")
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 11)
                                            if i < 3 {
                                                Divider().padding(.leading, 16)
                                            }
                                        }
                                    }
                                    .background(Color(.secondarySystemGroupedBackground),
                                                 in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                    }

                    // MARK: Grouped
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grouped")
                            .font(.headline)
                        Text(".listStyle(.grouped)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(["Section A", "Section B"], id: \.self) { section in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(section)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 20)
                                        .padding(.bottom, 6)
                                    VStack(spacing: 0) {
                                        ForEach(1...3, id: \.self) { i in
                                            HStack {
                                                Text("Row \(i)")
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 11)
                                            .background(Color(.secondarySystemGroupedBackground))
                                            if i < 3 {
                                                Divider().padding(.leading, 16)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                    }

                    // MARK: Row Types — real interactive rows below
                    Text("Row Types")
                        .font(.headline)
                        .padding(.top, 4)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Basic") {
                Text("Simple text row")
                HStack {
                    Text("Label")
                    Spacer()
                    Text("Value").foregroundStyle(.secondary)
                }
                NavigationLink("With disclosure indicator") { Text("Detail") }
            }

            Section("With Icons") {
                Label("Maps", systemImage: "map")
                Label("Settings", systemImage: "gear")
                    .foregroundStyle(.primary)
                Label {
                    VStack(alignment: .leading) {
                        Text("Title")
                        Text("Subtitle").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }

            Section("Subtitle") {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Primary text")
                    Text("Secondary subtitle text").font(.footnote).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Another item")
                    Text("With a longer subtitle that might wrap to two lines on smaller devices")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("With Controls") {
                Toggle("Toggle in row", isOn: $checked)
                Stepper("Stepper in row", value: .constant(3), in: 0...10)
                Button("Button row") {}
            }

            Section("Swipe Actions") {
                Text("Swipe left →")
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {} label: { Label("Delete", systemImage: "trash") }
                        Button {} label: { Label("Archive", systemImage: "archivebox") }
                            .tint(.orange)
                    }
                Text("← Swipe right")
                    .swipeActions(edge: .leading) {
                        Button {} label: { Label("Flag", systemImage: "flag") }
                            .tint(.yellow)
                    }
            }
        }
        .navigationTitle("Lists & Tables")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - GridsView

struct GridsView: View {
    private enum Mode: String, CaseIterable {
        case fixed = "Fixed columns"
        case adaptive = "Adaptive"
    }

    @State private var mode: Mode = .fixed
    @State private var columnCount = 3.0
    @State private var minWidth: CGFloat = 120
    @State private var spacing: CGFloat = 8
    @State private var itemCount = 9.0
    @State private var tileHeight: CGFloat = 80

    private var gridColumns: [GridItem] {
        switch mode {
        case .fixed:
            return Array(repeating: GridItem(.flexible(), spacing: spacing), count: Int(columnCount))
        case .adaptive:
            return [GridItem(.adaptive(minimum: minWidth), spacing: spacing)]
        }
    }

    private var generatedCode: String {
        switch mode {
        case .fixed:
            return "LazyVGrid(columns: Array(\n  repeating: GridItem(.flexible(), spacing: \(Int(spacing))),\n  count: \(Int(columnCount))\n), spacing: \(Int(spacing)))"
        case .adaptive:
            return "LazyVGrid(columns: [GridItem(\n  .adaptive(minimum: \(Int(minWidth))),\n  spacing: \(Int(spacing))\n)], spacing: \(Int(spacing)))"
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    LazyVGrid(columns: gridColumns, spacing: spacing) {
                        ForEach(0..<Int(itemCount), id: \.self) { i in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.tint.opacity(0.2))
                                .frame(height: tileHeight)
                                .overlay(Text("\(i + 1)").font(.caption))
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .animation(.spring(duration: 0.3), value: mode)
                    .animation(.spring(duration: 0.3), value: Int(columnCount))
                    .animation(.spring(duration: 0.3), value: Int(itemCount))

                    Text(generatedCode)
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .fixed {
                    LabeledContent("columns: \(Int(columnCount))") {
                        Slider(value: $columnCount, in: 2...5, step: 1)
                    }
                } else {
                    LabeledContent("minimum: \(Int(minWidth))") {
                        Slider(value: $minWidth, in: 80...200)
                    }
                }

                LabeledContent("spacing: \(Int(spacing))") {
                    Slider(value: $spacing, in: 0...24)
                }
                LabeledContent("items: \(Int(itemCount))") {
                    Slider(value: $itemCount, in: 4...24, step: 1)
                }
                LabeledContent("tile height: \(Int(tileHeight))") {
                    Slider(value: $tileHeight, in: 60...120)
                }
            }
        }
        .navigationTitle("Grids")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - GroupedFormsView (unchanged)

struct GroupedFormsView: View {
    @State private var name = ""
    @State private var notifications = true
    @State private var theme = "System"

    var body: some View {
        Form {
            Section("Account") {
                TextField("Full name", text: $name)
                HStack {
                    Text("Email")
                    Spacer()
                    Text("matt@example.com").foregroundStyle(.secondary)
                }
            }
            Section("Preferences") {
                Toggle("Push Notifications", isOn: $notifications)
                Picker("Appearance", selection: $theme) {
                    ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) }
                }
                NavigationLink("Privacy") { Text("Privacy settings") }
            }
            Section {
                Button("Sign Out", role: .destructive) {}
            }
        }
        .navigationTitle("Forms")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        ListsView()
    }
}
