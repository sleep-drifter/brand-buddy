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
                .buttonStyle(.borderedProminent)
            }

            Section {
                // Basic context menu
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .frame(width: 60, height: 60)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Basic context menu")
                            .font(.subheadline)
                        Text("Long press to reveal actions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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

                // iMessage-style: preview reveals hidden content
                ForEach(InlineMessageItem.samples) { msg in
                    MessageContextRow(msg: msg)
                }

                // Spotify-style: preview shows rich album art
                ForEach(InlineTrackItem.samples) { track in
                    TrackContextRow(track: track)
                }
            } header: {
                Text("Context Menu (long press)")
            } footer: {
                Text("Use contextMenu(menuItems:preview:) to show a custom preview — it can reveal content not visible in the list.")
            }

        }
        .navigationTitle("Menus & Context Menus")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Inline context menu models & rows

private struct InlineMessageItem: Identifiable {
    let id = UUID()
    let sender: String
    let snippet: String
    let fullMessage: String
    let time: String

    static let samples = [
        InlineMessageItem(sender: "Sarah K.", snippet: "Are you free tomorrow?", fullMessage: "Hey! Are you free tomorrow afternoon? Thinking of grabbing coffee and catching up — it's been ages. Let me know!", time: "2m ago"),
        InlineMessageItem(sender: "Team iOS", snippet: "Build passed ✓", fullMessage: "🎉 Build #1042 passed all checks. Ready to submit to TestFlight. Great work everyone on shipping the new camera module!", time: "14m ago"),
    ]
}

private struct MessageContextRow: View {
    let msg: InlineMessageItem
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(Text(String(msg.sender.prefix(1))).font(.subheadline.bold()).foregroundStyle(.tint))
            VStack(alignment: .leading, spacing: 2) {
                Text(msg.sender).font(.subheadline).fontWeight(.semibold)
                Text(msg.snippet).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(msg.time).font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("Reply", systemImage: "arrowshape.turn.up.left") {}
            Button("Copy", systemImage: "doc.on.doc") {}
            Button("Delete", systemImage: "trash", role: .destructive) {}
        } preview: {
            VStack(alignment: .leading, spacing: 10) {
                Text(msg.sender).font(.headline)
                Text(msg.fullMessage).font(.body).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(width: 300, alignment: .leading)
        }
    }
}

private struct InlineTrackItem: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let color: Color

    static let samples = [
        InlineTrackItem(title: "Midnight City", artist: "M83", color: .indigo),
        InlineTrackItem(title: "Redbone",       artist: "Childish Gambino", color: .orange),
    ]
}

private struct TrackContextRow: View {
    let track: InlineTrackItem
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(track.color.gradient)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "music.note").foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.subheadline).fontWeight(.medium)
                Text(track.artist).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "ellipsis").foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") {}
            Button("Add to Playlist", systemImage: "plus") {}
            Button("Share Song", systemImage: "square.and.arrow.up") {}
        } preview: {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(track.color.gradient)
                    .frame(width: 200, height: 200)
                    .overlay(Image(systemName: "music.note").font(.system(size: 64)).foregroundStyle(.white.opacity(0.8)))
                VStack(spacing: 4) {
                    Text(track.title).font(.title3.bold())
                    Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(20)
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

            // MARK: iOS 26 Glass Button Groups
            Section {
                NavigationLink("Single icon button")         { ButtonGroupDemo(variant: .single) }
                NavigationLink("Two-button group")           { ButtonGroupDemo(variant: .two) }
                NavigationLink("Three-button group")         { ButtonGroupDemo(variant: .three) }
                NavigationLink("Label + icon group (mixed)") { ButtonGroupDemo(variant: .mixed) }
                NavigationLink("Leading + trailing groups")  { ButtonGroupDemo(variant: .bothSides) }
                NavigationLink("ControlGroup")               { ButtonGroupDemo(variant: .controlGroup) }
            } header: {
                Text("iOS 26 glass button groups")
            } footer: {
                Text("Adjacent buttons inside ToolbarItemGroup are merged into a glass pill. Use ControlGroup to force grouping across separate ToolbarItem blocks.")
            }

            // MARK: Live demos
            Section {
                NavigationLink("Primary action (Save + Cancel)") { PrimaryActionDemo() }
                NavigationLink("Bottom bar (.bottomBar)")         { BottomBarDemo() }
                NavigationLink("Keyboard toolbar")                { KeyboardToolbarDemo() }
                NavigationLink("Confirmation / Cancellation")     { ConfirmationDemo() }
                NavigationLink("Principal (center replace)")      { PrincipalDemo() }
            } header: {
                Text("Live demos")
            } footer: {
                Text("Per HIG, use .borderedProminent for confirm/save actions in modal sheets. Plain style for cancel.")
            }

            // MARK: Placement reference
            Section {
                PlacementRow(token: ".navigationBarLeading",  description: "Left side of the navigation bar",          example: "Cancel, back, edit")
                PlacementRow(token: ".navigationBarTrailing", description: "Right side of the navigation bar",         example: "Done, Save, Add (+)")
                PlacementRow(token: ".principal",             description: "Center — replaces the title",              example: "Segmented control, custom title")
                PlacementRow(token: ".bottomBar",             description: "Bottom toolbar, above the tab bar",        example: "Mail compose, document actions")
                PlacementRow(token: ".confirmationAction",    description: "Primary action, trailing",                 example: "Done, Send")
                PlacementRow(token: ".cancellationAction",    description: "Cancel action, leading",                   example: "Cancel")
                PlacementRow(token: ".destructiveAction",     description: "Destructive action (red)",                 example: "Delete")
                PlacementRow(token: ".keyboard",              description: "Floats above the software keyboard",       example: "Format, done, emoji")
                PlacementRow(token: ".automatic",             description: "System chooses the best placement",        example: "Default for most items")
            } header: {
                Text("Placements")
            }

            // MARK: Visibility
            Section {
                PlacementRow(token: ".toolbar(.hidden)",                   description: "Hides the nav bar or tab bar",  example: "Full-screen reader, media player")
                PlacementRow(token: ".toolbar(.hidden, for: .tabBar)",    description: "Hides only the tab bar",         example: "Detail views inside a tab")
            } header: {
                Text("Visibility")
            }
        }
        .navigationTitle("Toolbars")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Button Group Demos

private enum ButtonGroupVariant {
    case single, two, three, mixed, bothSides, controlGroup
}

private struct ButtonGroupDemo: View {
    let variant: ButtonGroupVariant
    @State private var lastTapped: String? = nil

    var title: String {
        switch variant {
        case .single:       return "Single button"
        case .two:          return "Two-button group"
        case .three:        return "Three-button group"
        case .mixed:        return "Label + icon group"
        case .bothSides:    return "Both sides"
        case .controlGroup: return "ControlGroup"
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Look at the navigation bar above to see the glass button group in context.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let t = lastTapped {
                        Label("Tapped: \(t)", systemImage: "hand.tap")
                            .font(.subheadline.bold())
                            .foregroundStyle(.tint)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.3), value: lastTapped)
                .padding(.vertical, 4)
            }

            Section("Pattern") {
                CodeSnippetRow(code: codeSnippet)
            }

            Section("Notes") {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        switch variant {

        case .single:
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { lastTapped = "Grid" } label: { Image(systemName: "square.grid.2x2") }
            }

        case .two:
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { lastTapped = "Select" } label: { Image(systemName: "checkmark.circle") }
                Button { lastTapped = "Share" } label: { Image(systemName: "square.and.arrow.up") }
            }

        case .three:
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { lastTapped = "Sort" }  label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                Button { lastTapped = "Grid" }  label: { Image(systemName: "square.grid.2x2") }
                Button { lastTapped = "More" }  label: { Image(systemName: "ellipsis") }
            }

        case .mixed:
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { lastTapped = "Edit" } label: { Text("Edit") }
                Button { lastTapped = "Share" } label: { Image(systemName: "square.and.arrow.up") }
                Button { lastTapped = "More" }  label: { Image(systemName: "ellipsis") }
            }

        case .bothSides:
            ToolbarItem(placement: .navigationBarLeading) {
                Button { lastTapped = "Close" } label: { Image(systemName: "xmark") }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { lastTapped = "Select" } label: { Image(systemName: "checkmark.circle") }
                Button { lastTapped = "More" }   label: { Image(systemName: "ellipsis") }
            }

        case .controlGroup:
            ToolbarItem(placement: .navigationBarTrailing) {
                ControlGroup {
                    Button { lastTapped = "Decrease" } label: { Image(systemName: "minus") }
                    Button { lastTapped = "Increase" } label: { Image(systemName: "plus") }
                }
            }
        }
    }

    private var codeSnippet: String {
        switch variant {
        case .single:
            return """
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
                """
        case .two:
            return """
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "checkmark.circle") }
                    Button { } label: { Image(systemName: "square.and.arrow.up") }
                }
                """
        case .three:
            return """
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                    Button { } label: { Image(systemName: "square.grid.2x2") }
                    Button { } label: { Image(systemName: "ellipsis") }
                }
                """
        case .mixed:
            return """
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Edit") { }
                    Button { } label: { Image(systemName: "square.and.arrow.up") }
                    Button { } label: { Image(systemName: "ellipsis") }
                }
                """
        case .bothSides:
            return """
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { } label: { Image(systemName: "xmark") }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "checkmark.circle") }
                    Button { } label: { Image(systemName: "ellipsis") }
                }
                """
        case .controlGroup:
            return """
                ToolbarItem(placement: .navigationBarTrailing) {
                    ControlGroup {
                        Button { } label: { Image(systemName: "minus") }
                        Button { } label: { Image(systemName: "plus") }
                    }
                }
                """
        }
    }

    private var notes: String {
        switch variant {
        case .single:       return "A lone icon button gets the round glass pill shape. Text labels stay as plain buttons."
        case .two:          return "Two adjacent icons merge into a single elongated glass pill — the pattern shown in the iOS 26 Mail and Files apps."
        case .three:        return "Three buttons form a wider pill. Beyond three, consider moving secondary actions to a menu."
        case .mixed:        return "Mixing a text label with icons breaks the automatic glass grouping on some seeds — test carefully."
        case .bothSides:    return "Leading and trailing groups render independently. The leading close/xmark gets its own pill."
        case .controlGroup: return "ControlGroup provides explicit visual grouping regardless of how many separate ToolbarItem blocks you use. Ideal for stepper-style controls."
        }
    }
}

// MARK: - Sub-views

private struct PlacementRow: View {
    let token: String
    let description: String
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(token)
                .font(.mono(.subheadline))
                .foregroundStyle(.primary)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("e.g. \(example)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

private struct CodeSnippetRow: View {
    let code: String
    var body: some View {
        Text(code)
            .font(.mono(.caption))
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct PrimaryActionDemo: View {
    @State private var showSheet = false

    var body: some View {
        List {
            Section {
                Text("The most common modal toolbar pattern: a plain **Cancel** on the leading side and a filled **.borderedProminent** **Save** on the trailing side.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Open demo sheet") { showSheet = true }
            }
            Section("HIG guidance") {
                Text("Use a filled primary button for the confirmation action in modal sheets. It draws the eye to the intended next step and distinguishes it clearly from the destructive cancel path.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Code") {
                CodeSnippetRow(code: """
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .buttonStyle(.borderedProminent)
                    }
                    """)
            }
        }
        .navigationTitle("Primary Action")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSheet) {
            PrimaryActionSheet()
        }
    }
}

private struct PrimaryActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Enter a value…", text: $value)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .disabled(value.isEmpty)
                }
            }
        }
    }
}

private struct BottomBarDemo: View {
    @State private var lastTapped: String? = nil

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The three icons below are `.bottomBar` toolbar items. Tap any to confirm they respond.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let t = lastTapped {
                        Label("Tapped: \(t)", systemImage: "hand.tap")
                            .font(.subheadline.bold())
                            .foregroundStyle(.tint)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.3), value: lastTapped)
                .padding(.vertical, 4)
            }
            Section("Code") {
                CodeSnippetRow(code: """
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { } label: { Image(systemName: "trash") }
                        Spacer()
                        Button { } label: { Image(systemName: "square.and.arrow.up") }
                        Spacer()
                        Button { } label: { Image(systemName: "folder") }
                    }
                    """)
            }
        }
        .navigationTitle("Bottom bar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { lastTapped = "Trash" }  label: { Image(systemName: "trash") }
                Spacer()
                Button { lastTapped = "Share" }  label: { Image(systemName: "square.and.arrow.up") }
                Spacer()
                Button { lastTapped = "Move" }   label: { Image(systemName: "folder") }
            }
        }
    }
}

private struct KeyboardToolbarDemo: View {
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        Form {
            Section("Type something") {
                TextField("Message…", text: $text, axis: .vertical)
                    .lineLimit(4...)
                    .focused($focused)
            }
            Section("Code") {
                CodeSnippetRow(code: """
                    ToolbarItemGroup(placement: .keyboard) {
                        Button { } label: { Image(systemName: "bold") }
                        Button { } label: { Image(systemName: "italic") }
                        Spacer()
                        Button("Done") { focused = false }
                    }
                    """)
            }
        }
        .navigationTitle("Keyboard toolbar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Divider()
                Button { text += "😊" }        label: { Image(systemName: "face.smiling") }
                Button { text += "**bold** " } label: { Image(systemName: "bold") }
                Button { text += "_italic_ " } label: { Image(systemName: "italic") }
                Spacer()
                Button("Done") { focused = false }.fontWeight(.semibold)
            }
        }
        .onAppear { focused = true }
    }
}

private struct ConfirmationDemo: View {
    @State private var showSheet = false

    var body: some View {
        List {
            Section {
                Text("`.confirmationAction` and `.cancellationAction` auto-position Cancel (leading) and Done/Save (trailing) correctly across all platforms.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Open sheet demo") { showSheet = true }
            }
            Section("Code") {
                CodeSnippetRow(code: """
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                    }
                    """)
            }
        }
        .navigationTitle("Confirmation / Cancel")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSheet) {
            ConfirmationSheetDemo()
        }
    }
}

private struct ConfirmationSheetDemo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New item") {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
}

private struct PrincipalDemo: View {
    @State private var selection = "All"
    let segments = ["All", "Photos", "Videos"]

    var body: some View {
        List {
            Section {
                Text("The segmented control above is a `.principal` toolbar item — it replaces the navigation title in the center of the nav bar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Selected: **\(selection)**")
                    .font(.subheadline)
            }
            Section("Code") {
                CodeSnippetRow(code: """
                    ToolbarItem(placement: .principal) {
                        Picker("", selection: $selection) {
                            ForEach(segments, id: \\.self) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    """)
            }
        }
        .navigationTitle("Principal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $selection) {
                    ForEach(segments, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 200)
            }
        }
    }
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
