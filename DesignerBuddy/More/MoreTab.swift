import SwiftUI

struct MoreTab: View {
    @EnvironmentObject var pinsStore: PinsStore

    private let tabEntries: [AppEntry] = AppEntry.more
    private let sectionOrder = ["Playgrounds", "Reference"]

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
            .navigationTitle("More")
            .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
        }
    }
}

#Preview {
    MoreTab()
        .environmentObject(PinsStore())
}
