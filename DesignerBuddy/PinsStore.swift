import SwiftUI

@MainActor
final class PinsStore: ObservableObject {
    @AppStorage("pinnedItemKeys") private var data: Data = Data()

    var pinnedKeys: Set<String> {
        get { (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? [] }
        set {
            objectWillChange.send()
            data = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    func isPinned(_ entry: AppEntry) -> Bool {
        pinnedKeys.contains(entry.pinKey)
    }

    func toggle(_ entry: AppEntry) {
        var keys = pinnedKeys
        if keys.contains(entry.pinKey) { keys.remove(entry.pinKey) }
        else { keys.insert(entry.pinKey) }
        pinnedKeys = keys
    }
}
