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

// MARK: - GridsView (unchanged)

struct GridsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("LazyVGrid — 3 columns")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(0..<9) { i in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.tint.opacity(0.2))
                            .frame(height: 80)
                            .overlay(Text("\(i + 1)").font(.caption))
                    }
                }
                .padding(.horizontal)

                Text("LazyVGrid — 2 columns (adaptive)")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(0..<6) { i in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.tint.opacity(0.15))
                            .frame(height: 100)
                            .overlay(Text("Item \(i + 1)").font(.caption))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
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
