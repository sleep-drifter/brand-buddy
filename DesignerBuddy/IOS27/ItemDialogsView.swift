import SwiftUI

// iOS 27 item-bound alerts and dialogs: confirmationDialog and alert accept
// item: Binding<T?> exactly like sheet(item:) — set the optional and the
// presentation appears with that value in hand; nil dismisses. No separate
// Boolean plus stashed optional.

private struct Teammate: Identifiable, Equatable {
    let id: Int
    let name: String
    let role: String
    let color: Color
}

struct ItemDialogsView: View {
    private let team: [Teammate] = [
        .init(id: 0, name: "Priya",  role: "Design",   color: .pink),
        .init(id: 1, name: "Marcus", role: "iOS",      color: .indigo),
        .init(id: 2, name: "Sam",    role: "Backend",  color: .teal),
        .init(id: 3, name: "Ines",   role: "Research", color: .orange),
        .init(id: 4, name: "Kofi",   role: "Motion",   color: .purple),
    ]

    @State private var toRemove: Teammate?
    @State private var toPromote: Teammate?
    @State private var log = "No dialog shown yet."

    var body: some View {
        List {
            Section {
                Text("Tap a teammate for a confirmation dialog, long-press for an alert. Both presentations are driven by `item:` bindings — the tapped value rides along, so the actions and message can reference it directly.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Team — tap or long-press") {
                ForEach(team) { member in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(member.color.gradient)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Text(member.name.prefix(1))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                            Text(member.role).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "hand.tap")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { toRemove = member }
                    .onLongPressGesture { toPromote = member }
                }
            }

            Section("Event log") {
                Text(log)
                    .font(.mono(.caption))
                    .foregroundStyle(.secondary)
            }

            Section("How it works") {
                Text("Before iOS 27 this took an `isPresented` Bool *and* a separately stored optional (or the `presenting:` argument). With `item:` there is one piece of state: setting it presents, the closures receive the unwrapped value, and dismissal writes back nil — the same mental model as `sheet(item:)`.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Item Dialogs")
        .confirmationDialog("Remove teammate?", item: $toRemove) { member in
            Button("Remove \(member.name)", role: .destructive) {
                log = "Removed \(member.name) via confirmationDialog(item:)"
            }
            Button("Cancel", role: .cancel) { }
        } message: { member in
            Text("\(member.name) (\(member.role)) will lose access to the project immediately.")
        }
        .alert("Promote to lead?", item: $toPromote) { member in
            Button("Promote") {
                log = "Promoted \(member.name) via alert(item:)"
            }
            Button("Cancel", role: .cancel) { }
        } message: { member in
            Text("\(member.name) will become the \(member.role) lead.")
        }
    }
}

#Preview {
    NavigationStack { ItemDialogsView() }
        .environmentObject(PinsStore())
}
