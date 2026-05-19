import SwiftUI

struct PatternsTab: View {
    @EnvironmentObject var pinsStore: PinsStore

    private let tabEntries: [AppEntry] = AppEntry.patterns
    private let sectionOrder = ["Navigation", "Presentation", "Input & Search",
                                "Content", "Settings", "Onboarding"]

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
            .navigationTitle("Patterns")
            .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
        }
    }
}

#Preview {
    PatternsTab()
        .environmentObject(PinsStore())
}
