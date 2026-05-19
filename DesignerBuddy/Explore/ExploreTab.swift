import SwiftUI

// MARK: - Explore Tab

struct ExploreTab: View {
    @EnvironmentObject var pinsStore: PinsStore

    private let tabEntries: [AppEntry] = AppEntry.exploreA + AppEntry.exploreB + AppEntry.exploreC + AppEntry.exploreD
    private let sectionOrder = ["Gestures", "Animations", "Accessibility",
                                "System Integrations", "AI & Generation", "Device & Sensors"]

    private var pinnedEntries: [AppEntry] {
        tabEntries.filter { pinsStore.isPinned($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !pinnedEntries.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedEntries) { entry in
                            pinnableRow(entry, pinsStore: pinsStore)
                        }
                    }
                }

                ForEach(sectionOrder, id: \.self) { section in
                    let entries = tabEntries.filter { $0.section == section }
                    if !entries.isEmpty {
                        Section(section) {
                            ForEach(entries) { entry in
                                pinnableRow(entry, pinsStore: pinsStore)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
        }
    }
}

#Preview {
    ExploreTab()
        .environmentObject(PinsStore())
}
