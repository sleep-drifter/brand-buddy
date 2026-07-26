import SwiftUI

// iOS 27 toolbar control: the nav bar condenses on scroll via
// toolbarMinimizeBehavior, visibilityPriority decides which items survive
// tight widths (resizable iPhone apps make this real), ToolbarOverflowMenu
// pins low-frequency commands into the overflow permanently, and
// .topBarPinnedTrailing keeps a critical action from ever leaving the bar.
// This page's own navigation bar is the demo — scroll the list.

struct ToolbarMinimizeView: View {
    @State private var lastAction = "Tap a toolbar action."

    var body: some View {
        List {
            Section {
                Text("Scroll down and the navigation bar minimizes into a compact strip (`.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)`); scroll back up and it returns. The share button is pinned trailing, the wand and brush are a high-priority group, and two more commands live permanently in the overflow menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Last toolbar action") {
                Text(lastAction)
                    .font(.mono(.caption))
                    .foregroundStyle(.secondary)
            }

            Section("Scroll to minimize") {
                ForEach(0..<28, id: \.self) { i in
                    HStack(spacing: 12) {
                        Circle().fill(Color(.systemFill)).frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 5) {
                            Capsule().fill(Color(.systemFill)).frame(width: 130, height: 8)
                            Capsule().fill(Color(.quaternarySystemFill)).frame(width: 84, height: 8)
                        }
                        Spacer()
                        Text("\(i + 1)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }

            Section("How it works") {
                Text("`visibilityPriority(.high)` marks the group that should survive when the window gets narrow — with resizable iPhone apps on iOS 27, bars genuinely run out of room, and lower-priority items collapse into overflow instead of clipping.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("`ToolbarOverflowMenu` is for commands that should always live in the overflow, and `.topBarPinnedTrailing` guarantees placement for the one action people reach for constantly. Toolbar builders also accept `ForEach` and `EmptyView` now. The hand-rolled glass version of chrome-condensing lives in the Toolbar Condense playground; this is the system behavior.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Toolbar Minimize")
        .toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    lastAction = "Wand (high-priority group)"
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                Button {
                    lastAction = "Brush (high-priority group)"
                } label: {
                    Image(systemName: "paintbrush")
                }
            }
            .visibilityPriority(.high)

            ToolbarOverflowMenu {
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    lastAction = "Duplicate (overflow)"
                }
                Button("Export", systemImage: "square.and.arrow.down") {
                    lastAction = "Export (overflow)"
                }
            }

            ToolbarItem(placement: .topBarPinnedTrailing) {
                Button {
                    lastAction = "Share (pinned trailing)"
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ToolbarMinimizeView() }
        .environmentObject(PinsStore())
}
