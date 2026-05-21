import SwiftUI

enum SectionDest: Hashable {
    case components, patterns, native, explore, playgrounds
}

struct HomeView: View {
    @EnvironmentObject var pinsStore: PinsStore
    @State private var showSaved = false
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 32) {
                    HomeSectionRow(
                        title: "Components",
                        entries: AppEntry.components + AppEntry.materials,
                        dest: SectionDest.components
                    )
                    HomeSectionRow(
                        title: "Patterns",
                        entries: AppEntry.patterns,
                        dest: SectionDest.patterns
                    )
                    HomeSectionRow(
                        title: "Native",
                        entries: AppEntry.native,
                        dest: SectionDest.native
                    )
                    HomeSectionRow(
                        title: "Explore",
                        entries: AppEntry.exploreA + AppEntry.exploreB + AppEntry.exploreC + AppEntry.exploreD,
                        dest: SectionDest.explore
                    )
                    HomeSectionRow(
                        title: "Playgrounds",
                        entries: AppEntry.more,
                        dest: SectionDest.playgrounds
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .navigationTitle("Designer Buddy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSaved = true } label: {
                        Image(systemName: "bookmark")
                            .padding(8)
                            .background(Color(.secondarySystemBackground), in: Circle())
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person")
                            .padding(8)
                            .background(Color(.secondarySystemBackground), in: Circle())
                    }
                }
            }
            .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
            .navigationDestination(for: SectionDest.self) { dest in
                switch dest {
                case .components:
                    CategoryListView(
                        title: "Components",
                        entries: AppEntry.components + AppEntry.materials,
                        sectionOrder: ["Visual", "Actions", "Inputs", "Selection", "Display",
                                       "Layout", "Navigation", "Overlays", "Glass", "Surfaces", "Vibrancy"]
                    )
                case .patterns:
                    CategoryListView(
                        title: "Patterns",
                        entries: AppEntry.patterns,
                        sectionOrder: ["Navigation", "Presentation", "Input & Search",
                                       "Lists", "Content", "Settings", "Onboarding"]
                    )
                case .native:
                    CategoryListView(
                        title: "Native",
                        entries: AppEntry.native,
                        sectionOrder: ["Permissions", "Camera", "Photo Library", "Audio", "Maps"]
                    )
                case .explore:
                    CategoryListView(
                        title: "Explore",
                        entries: AppEntry.exploreA + AppEntry.exploreB + AppEntry.exploreC + AppEntry.exploreD,
                        sectionOrder: ["Gestures", "Animations", "Accessibility",
                                       "System Integrations", "AI & Generation", "Device & Sensors"]
                    )
                case .playgrounds:
                    CategoryListView(
                        title: "Playgrounds",
                        entries: AppEntry.more,
                        sectionOrder: ["Playgrounds", "Reference"]
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                NavigationLink {
                    ComponentSearchView()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Find something specific")
                        Spacer()
                        Image(systemName: "mic")
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 4)
            }
            .sheet(isPresented: $showSaved) {
                SavedView()
                    .environmentObject(pinsStore)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }
}

// MARK: - Home Section Row

struct HomeSectionRow: View {
    let title: String
    let entries: [AppEntry]
    let dest: SectionDest

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private var previewEntries: [AppEntry] { Array(entries.prefix(6)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: dest) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.callout.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(previewEntries) { entry in
                    NavigationLink(value: entry) {
                        EntryGridCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Entry Grid Card

struct EntryGridCard: View {
    let entry: AppEntry

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: entry.icon)
                .font(.title2)
                .foregroundStyle(.primary)
            Text(entry.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Category List View (shared section detail view)

struct CategoryListView: View {
    @EnvironmentObject var pinsStore: PinsStore
    let title: String
    let entries: [AppEntry]
    let sectionOrder: [String]

    var body: some View {
        List {
            ForEach(sectionOrder, id: \.self) { section in
                let sectionEntries = entries.filter { $0.section == section }
                if !sectionEntries.isEmpty {
                    Section(section) {
                        ForEach(sectionEntries) { entry in
                            pinnableRow(entry, pinsStore: pinsStore)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
    }
}

#Preview {
    HomeView()
        .environmentObject(PinsStore())
}
