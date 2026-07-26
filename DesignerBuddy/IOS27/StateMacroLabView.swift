import SwiftUI

// iOS 27's @State is a macro, not a property wrapper. The visible win:
// classes assigned as a @State default are now initialized lazily, exactly
// once per view lifetime — instead of on every re-render of the parent (with
// the extras thrown away). This lab counts real initializations so you can
// watch the difference.

/// Counts every init. MainActor-bound so the running total is safe to touch
/// from view code.
@MainActor
final class CountingModel {
    static var totalInits = 0
    let serial: Int

    init() {
        CountingModel.totalInits += 1
        serial = CountingModel.totalInits
    }
}

struct StateMacroLabView: View {
    @State private var rerenders = 0
    @State private var identityToken = 0

    var body: some View {
        List {
            Section {
                Text("The card below stores `@State private var model = CountingModel()`. Re-rendering its parent used to construct a fresh throwaway model each time; with the @State macro the initializer runs once per view lifetime. Watch the init counter as you press the buttons.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Lab") {
                LabCard(rerenders: rerenders)
                    .id(identityToken)

                Button {
                    rerenders += 1
                } label: {
                    Label("Re-render parent (\(rerenders))", systemImage: "arrow.clockwise")
                }

                Button {
                    identityToken += 1
                } label: {
                    Label("Reset view identity", systemImage: "arrow.uturn.backward.circle")
                }
            }

            Section("How it works") {
                Text("Re-render should leave the model's serial and the total init count untouched — lazy, once-per-lifetime initialization. Reset identity gives the card a new `.id`, which is a new lifetime, so the model re-initializes and the counter climbs by exactly one.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Because @State is now a macro, one old pattern breaks: assigning an initial value at the declaration and then reassigning it in `init` no longer compiles. Set state defaults in one place — the declaration — or inject through the initializer only.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("@State Macro Lab")
    }
}

private struct LabCard: View {
    let rerenders: Int
    @State private var model = CountingModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cube.fill")
                    .foregroundStyle(.tint)
                Text("Model serial #\(model.serial)")
                    .font(.headline)
            }
            Text("Total CountingModel inits: \(CountingModel.totalInits)")
                .font(.mono(.caption))
                .foregroundStyle(.secondary)
            Text("Parent re-renders seen: \(rerenders)")
                .font(.mono(.caption))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { StateMacroLabView() }
        .environmentObject(PinsStore())
}
