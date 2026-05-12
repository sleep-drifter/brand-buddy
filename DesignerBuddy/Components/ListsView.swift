import SwiftUI

struct ListsView: View {
    var body: some View {
        List {
            Section("Plain Style") {
                NavigationLink("Plain list") { PlainListDemo() }
            }
            Section("Inset Grouped (default)") {
                NavigationLink("Inset grouped") { InsetGroupedDemo() }
            }
            Section("Grouped") {
                NavigationLink("Grouped") { GroupedDemo() }
            }
            Section("Row Types") {
                NavigationLink("Row variants") { RowVariantsDemo() }
            }
        }
        .navigationTitle("Lists & Tables")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PlainListDemo: View {
    var body: some View {
        List {
            ForEach(0..<8) { i in
                Text("Row \(i + 1)")
            }
        }
        .listStyle(.plain)
        .navigationTitle("Plain")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InsetGroupedDemo: View {
    var body: some View {
        List {
            Section("Section A") {
                ForEach(0..<3) { i in Text("Row \(i + 1)") }
            }
            Section("Section B") {
                ForEach(0..<3) { i in Text("Row \(i + 1)") }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Inset Grouped")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GroupedDemo: View {
    var body: some View {
        List {
            Section("Section A") {
                ForEach(0..<3) { i in Text("Row \(i + 1)") }
            }
            Section("Section B") {
                ForEach(0..<3) { i in Text("Row \(i + 1)") }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Grouped")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RowVariantsDemo: View {
    @State private var checked = false

    var body: some View {
        List {
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
        .navigationTitle("Row Variants")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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

struct ScrollViewsView: View {
    var body: some View {
        List {
            Section("Vertical (default)") {
                NavigationLink("Vertical scroll") {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<20) { i in
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.tint.opacity(0.1 + Double(i) * 0.04))
                                    .frame(height: 60)
                                    .overlay(Text("Item \(i + 1)"))
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .navigationTitle("Vertical")
                }
            }
            Section("Horizontal") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<10) { i in
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.tint.opacity(0.15))
                                .frame(width: 120, height: 80)
                                .overlay(Text("Card \(i + 1)").font(.caption))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Scroll Views")
        .navigationBarTitleDisplayMode(.large)
    }
}

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

struct CardsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardExample(
                    title: "Basic Card",
                    description: "A simple rounded rectangle with shadow"
                )
                CardExample(
                    title: "Card with Fill",
                    description: "Secondary background fill, no shadow"
                )
                .background(.secondarySystemBackground)
                HStack(spacing: 12) {
                    ForEach(["Card A", "Card B"], id: \.self) { title in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.secondarySystemBackground)
                            .frame(height: 120)
                            .overlay(Text(title).font(.headline))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CardExample: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(description).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.secondarySystemBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ListsView()
    }
}
