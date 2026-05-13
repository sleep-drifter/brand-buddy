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
                NavigationLink("Context Menus") { ContextMenusView() }
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

struct ContextMenusView: View {
    var body: some View {
        List {
            Section {
                Text("Long-press each row. The preview reveals content that isn't visible in the list — the key capability of contextMenu(preview:).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("iMessage-style") {
                ForEach(MessageThread.samples) { thread in
                    MessageRow(thread: thread)
                        .contextMenu {
                            Button("Reply", systemImage: "arrowshape.turn.up.left") {}
                            Button("React", systemImage: "face.smiling") {}
                            Button("Copy", systemImage: "doc.on.doc") {}
                            Button("Forward", systemImage: "arrowshape.turn.up.right") {}
                            Divider()
                            Button("Delete", systemImage: "trash", role: .destructive) {}
                        } preview: {
                            MessagePreview(thread: thread)
                        }
                }
            }

            Section("Spotify-style") {
                ForEach(Track.samples) { track in
                    TrackRow(track: track)
                        .contextMenu {
                            Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") {}
                            Button("Add to Queue", systemImage: "text.badge.plus") {}
                            Button("Save to Library", systemImage: "heart") {}
                            Divider()
                            Menu("Add to Playlist") {
                                Button("Chill Vibes") {}
                                Button("Morning Run") {}
                                Button("Focus") {}
                            }
                            Divider()
                            Button("Share Song", systemImage: "square.and.arrow.up") {}
                        } preview: {
                            TrackPreview(track: track)
                        }
                }
            }

            Section("Link / Rich Preview") {
                ForEach(LinkItem.samples) { link in
                    LinkRow(link: link)
                        .contextMenu {
                            Button("Open", systemImage: "safari") {}
                            Button("Copy Link", systemImage: "link") {}
                            Button("Share", systemImage: "square.and.arrow.up") {}
                            Divider()
                            Button("Remove", systemImage: "xmark.circle", role: .destructive) {}
                        } preview: {
                            LinkPreview(link: link)
                        }
                }
            }

            Section("API") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(".contextMenu { actions } preview: { customView }")
                        .font(.mono(.caption)).fontWeight(.medium)
                    Text("The preview can be any SwiftUI view — completely different from the source. It scales in from the tap point and shows above the action menu.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Use previews to surface detail that wouldn't fit in the list row: full message bodies, album art + metadata, link thumbnails, contact cards.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Context Menus")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - iMessage demo

struct MessageThread: Identifiable {
    let id = UUID()
    let sender: String
    let avatar: String
    let snippet: String
    let fullMessage: String
    let time: String
    let unread: Bool

    static let samples: [MessageThread] = [
        .init(sender: "Sarah K.", avatar: "person.circle.fill", snippet: "Are you coming to the…", fullMessage: "Are you coming to the design review tomorrow at 2pm? I think we'll need everyone's input on the new nav patterns before we ship.", time: "9:41 AM", unread: true),
        .init(sender: "Team iOS", avatar: "person.3.fill", snippet: "Build failed on main 🔴", fullMessage: "Build failed on main 🔴\n\nError: Type 'ShapeStyle' has no member 'tint'\nFile: MaterialsTab.swift:136\n\nLooks like another iOS 26 API change. Someone want to take a look?", time: "Yesterday", unread: false),
        .init(sender: "Marcus", avatar: "person.circle", snippet: "lgtm, shipping it 🚀", fullMessage: "lgtm, shipping it 🚀\n\nI went through the whole PR, left a couple minor comments but nothing blocking. Nice work on the glass effect section.", time: "Mon", unread: false),
    ]
}

struct MessageRow: View {
    let thread: MessageThread
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: thread.avatar)
                .font(.system(size: 36))
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(thread.sender).font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Text(thread.time).font(.caption).foregroundStyle(.secondary)
                }
                Text(thread.snippet).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            if thread.unread {
                Circle().fill(.tint).frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MessagePreview: View {
    let thread: MessageThread
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: thread.avatar)
                    .font(.system(size: 28))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thread.sender).font(.subheadline).fontWeight(.semibold)
                    Text(thread.time).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(thread.fullMessage)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - Spotify demo

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String
    let duration: String
    let color: Color

    static let samples: [Track] = [
        .init(title: "Midnight City", artist: "M83", album: "Hurry Up, We're Dreaming", duration: "4:03", color: .indigo),
        .init(title: "Redbone", artist: "Childish Gambino", album: "Awaken, My Love!", duration: "5:27", color: .red),
        .init(title: "Motion Picture Soundtrack", artist: "Radiohead", album: "Kid A", duration: "7:01", color: .teal),
    ]
}

struct TrackRow: View {
    let track: Track
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(track.color.gradient)
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "music.note").foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.subheadline).fontWeight(.medium)
                Text(track.artist).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(track.duration).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct TrackPreview: View {
    let track: Track
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(track.color.gradient)
                .frame(width: 280, height: 280)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title).font(.headline).fontWeight(.semibold)
                Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
                Text(track.album).font(.caption).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
        }
        .frame(width: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Link preview demo

struct LinkItem: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let description: String
    let color: Color
    let icon: String

    static let samples: [LinkItem] = [
        .init(title: "Apple HIG", url: "developer.apple.com", description: "Human Interface Guidelines — design patterns, components, and best practices for all Apple platforms.", color: .blue, icon: "apple.logo"),
        .init(title: "SwiftUI Docs", url: "developer.apple.com/documentation/swiftui", description: "Complete API reference for SwiftUI — views, modifiers, data flow, animations, and more.", color: .orange, icon: "swift"),
    ]
}

struct LinkRow: View {
    let link: LinkItem
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(link.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: link.icon).foregroundStyle(link.color).font(.system(size: 16)))
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title).font(.subheadline).fontWeight(.medium)
                Text(link.url).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct LinkPreview: View {
    let link: LinkItem
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(link.color.gradient)
                .frame(height: 140)
                .overlay(
                    Image(systemName: link.icon)
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                )
            VStack(alignment: .leading, spacing: 6) {
                Text(link.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(link.title)
                    .font(.headline)
                Text(link.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
        }
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        MenusView()
    }
}
