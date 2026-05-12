import SwiftUI

struct MenusView: View {
    var body: some View {
        List {
            Section("Pull-Down Menu") {
                Menu("Menu button") {
                    Button("New File", action: {})
                    Button("Open…", action: {})
                    Divider()
                    Menu("Share") {
                        Button("AirDrop", action: {})
                        Button("Messages", action: {})
                        Button("Mail", action: {})
                    }
                    Divider()
                    Button("Delete", role: .destructive, action: {})
                }
                Menu {
                    Button("Save", action: {})
                    Button("Duplicate", action: {})
                    Button("Delete", role: .destructive, action: {})
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }

            Section("Context Menu (long press)") {
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .frame(width: 60, height: 60)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("Long press for context menu")
                        .font(.subheadline)
                }
                .contextMenu {
                    Button("Share", systemImage: "square.and.arrow.up") {}
                    Button("Copy", systemImage: "doc.on.doc") {}
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {}
                } preview: {
                    Image(systemName: "photo")
                        .font(.system(size: 64))
                        .padding(24)
                        .background(.tint.opacity(0.1))
                }
            }

            Section("Menu with Selection") {
                MenuWithSelectionExample()
            }

            Section("Primary Action + Menu") {
                Menu {
                    Button("Option A") {}
                    Button("Option B") {}
                } label: {
                    Label("Tap or hold", systemImage: "plus")
                } primaryAction: {
                    // tap
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Menus & Context Menus")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct MenuWithSelectionExample: View {
    @State private var sort = "Name"

    var body: some View {
        Menu {
            Picker("Sort by", selection: $sort) {
                Text("Name").tag("Name")
                Text("Date").tag("Date")
                Text("Size").tag("Size")
            }
        } label: {
            HStack {
                Text("Sort: \(sort)")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ProgressIndicatorsView: View {
    @State private var progress = 0.6
    @State private var animating = false

    var body: some View {
        List {
            Section("Indeterminate (spinning)") {
                HStack(spacing: 16) {
                    ProgressView()
                    ProgressView().scaleEffect(1.5)
                    ProgressView().tint(.green)
                    ProgressView().tint(.orange)
                }
                .padding(.vertical, 8)
            }

            Section("Linear (determinate)") {
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                    ProgressView(value: progress)
                        .tint(.green)
                    ProgressView(value: 0.3)
                        .tint(.orange)
                    ProgressView(value: 1.0)
                        .tint(.red)
                }
                .padding(.vertical, 8)

                HStack {
                    Text("Progress:")
                    Slider(value: $progress)
                }
            }

            Section("With Label") {
                ProgressView(value: progress, total: 1.0) {
                    Text("Downloading…")
                } currentValueLabel: {
                    Text("\(Int(progress * 100))%")
                }
                .padding(.vertical, 8)
            }

            Section("Circular (explicit style)") {
                HStack(spacing: 20) {
                    VStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("circular").font(.mono(.caption2)).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 6) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .frame(width: 120)
                        Text("linear").font(.mono(.caption2)).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Progress Indicators")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct BadgesView: View {
    var body: some View {
        List {
            Section("Tab Bar Badge") {
                Text("TabView badges are applied via .badge() modifier on Tab items.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section("List Badge") {
                Label("Messages", systemImage: "message")
                    .badge(3)
                Label("Notifications", systemImage: "bell")
                    .badge("New")
                Label("Updates", systemImage: "arrow.down.circle")
                    .badge(99)
            }

            Section("Custom Badge Pattern") {
                HStack(spacing: 12) {
                    ForEach([1, 5, 12, 99, 100], id: \.self) { count in
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.title2)
                                .foregroundStyle(.tint)
                            Text(count < 100 ? "\(count)" : "99+")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.red, in: Capsule())
                                .offset(x: 8, y: -6)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TagsView: View {
    var body: some View {
        List {
            Section("Filled Tags") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["Design", "iOS 26", "SwiftUI", "HIG", "Material"], id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.tint.opacity(0.15), in: Capsule())
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Bordered Tags") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["SwiftUI", "Accessibility", "Animation"], id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .overlay(Capsule().strokeBorder(.secondary, lineWidth: 0.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct GaugesView: View {
    @State private var value = 0.65

    var body: some View {
        List {
            Section("Circular Gauge") {
                HStack(spacing: 24) {
                    Gauge(value: value) {}
                        .gaugeStyle(.accessoryCircular)
                    Gauge(value: value) {
                        Image(systemName: "bolt.fill")
                    } currentValueLabel: {
                        Text("\(Int(value * 100))")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                }
                .padding(.vertical, 8)
            }

            Section("Linear Gauge") {
                Gauge(value: value) {
                    Text("Battery")
                } currentValueLabel: {
                    Text("\(Int(value * 100))%")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("100")
                }
                .gaugeStyle(.accessoryLinear)

                Gauge(value: value) {}
                    .gaugeStyle(.accessoryLinearCapacity)
            }

            Section("Control") {
                Slider(value: $value, label: { Text("Value") })
            }
        }
        .navigationTitle("Gauges")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LabelsView: View {
    var body: some View {
        List {
            Section("Label Styles") {
                Label("Title and Icon", systemImage: "star")
                    .labelStyle(.titleAndIcon)
                Label("Title Only", systemImage: "star")
                    .labelStyle(.titleOnly)
                Label("Icon Only", systemImage: "star")
                    .labelStyle(.iconOnly)
            }
            Section("Text Roles") {
                Text("Primary text — .primary").foregroundStyle(.primary)
                Text("Secondary text — .secondary").foregroundStyle(.secondary)
                Text("Tertiary text — .tertiary").foregroundStyle(.tertiary)
                Text("Quaternary text — .quaternary").foregroundStyle(.quaternary)
                Text("Tint colored text").foregroundStyle(.tint)
                Text("Destructive/red text").foregroundStyle(.red)
            }
        }
        .navigationTitle("Labels & Text")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ImagesView: View {
    var body: some View {
        List {
            Section("Rendering Modes") {
                HStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .symbolRenderingMode(.monochrome)
                        Text(".monochrome").font(.mono(.caption2)).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .symbolRenderingMode(.hierarchical)
                        Text(".hierarchical").font(.mono(.caption2)).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .symbolRenderingMode(.multicolor)
                        Text(".multicolor").font(.mono(.caption2)).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.yellow, .orange)
                        Text(".palette").font(.mono(.caption2)).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            Section("Content Modes") {
                HStack(spacing: 12) {
                    ForEach([ContentMode.fit, .fill], id: \.self) { mode in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.quaternary)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: mode)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .foregroundStyle(.secondary)
                                )
                            Text(mode == .fit ? ".fit" : ".fill")
                                .font(.mono(.caption2)).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Images & Icons")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct NavigationBarsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("Large title (default)") {
                    List { ForEach(0..<5) { Text("Row \($0)") } }
                        .navigationTitle("Large Title")
                        .navigationBarTitleDisplayMode(.large)
                }
                NavigationLink("Inline title") {
                    List { ForEach(0..<5) { Text("Row \($0)") } }
                        .navigationTitle("Inline Title")
                        .navigationBarTitleDisplayMode(.inline)
                }
                NavigationLink("With toolbar items") {
                    List { ForEach(0..<5) { Text("Row \($0)") } }
                        .navigationTitle("With Toolbar")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Edit") {}
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button { } label: { Image(systemName: "plus") }
                            }
                        }
                }
            }
        }
        .navigationTitle("Navigation Bars")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TabBarsView: View {
    var body: some View {
        List {
            Section {
                Text("Tab bars are shown in the app's main TabView (ContentView). This reference covers tab bar specifications.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            Section("Specs") {
                LabeledContent("Height", value: "49pt (83pt with home indicator)")
                LabeledContent("Icon size", value: "25×25pt (50×50 @2x)")
                LabeledContent("Max tabs", value: "5 visible (overflow moves to More)")
                LabeledContent("Badge position", value: "Top-right of icon")
            }
        }
        .navigationTitle("Tab Bars")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ToolbarsView: View {
    var body: some View {
        List {
            Section("Toolbar Placements") {
                ForEach(ToolbarPlacementItem.all) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.token)
                            .font(.mono(.subheadline))
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Toolbars")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { } label: { Image(systemName: "trash") }
                Spacer()
                Button { } label: { Image(systemName: "square.and.arrow.up") }
                Spacer()
                Button { } label: { Image(systemName: "folder") }
            }
        }
    }
}

struct ToolbarPlacementItem: Identifiable {
    let id = UUID()
    let token: String
    let description: String

    static let all: [ToolbarPlacementItem] = [
        ToolbarPlacementItem(token: ".navigationBarLeading", description: "Left side of nav bar"),
        ToolbarPlacementItem(token: ".navigationBarTrailing", description: "Right side of nav bar"),
        ToolbarPlacementItem(token: ".principal", description: "Center of nav bar (replaces title)"),
        ToolbarPlacementItem(token: ".bottomBar", description: "Bottom toolbar above tab bar"),
        ToolbarPlacementItem(token: ".confirmationAction", description: "Primary action, trailing position"),
        ToolbarPlacementItem(token: ".cancellationAction", description: "Cancel action, leading position"),
        ToolbarPlacementItem(token: ".destructiveAction", description: "Destructive action (red)"),
        ToolbarPlacementItem(token: ".keyboard", description: "Above the keyboard"),
    ]
}

struct SearchComponentView: View {
    @State private var query = ""
    @State private var scope = "All"

    var body: some View {
        List {
            Section { Text("Using .searchable() modifier") }
            ForEach(["Apple", "Banana", "Cherry", "Date", "Elderberry"].filter {
                query.isEmpty || $0.localizedCaseInsensitiveContains(query)
            }, id: \.self) { item in
                Text(item)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search items")
        .searchScopes($scope) {
            Text("All").tag("All")
            Text("Recent").tag("Recent")
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SteppersView: View {
    @State private var count = 5

    var body: some View {
        List {
            Section("Default") {
                Stepper("Count: \(count)", value: $count, in: 0...20)
            }
            Section("With Step") {
                Stepper("Value: \(count)", value: $count, in: 0...100, step: 5)
            }
            Section("Custom Label") {
                Stepper(value: $count, in: 0...10) {
                    HStack {
                        Image(systemName: "person.2")
                        Text("\(count) guests")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationTitle("Steppers")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        MenusView()
    }
}
