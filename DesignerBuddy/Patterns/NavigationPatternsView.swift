import SwiftUI

struct NavigationPatternsView: View {
    var body: some View {
        List {
            Section("Push Navigation") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NavigationStack replaces NavigationView in iOS 16+. Always prefer NavigationStack for new code.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    NavigationLink("Tap to push") { PushedView(depth: 1) }
                }
                .padding(.vertical, 4)
            }

            Section("Navigation Path") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NavigationPath enables programmatic navigation — push/pop without a user tap.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("""
NavigationStack(path: $path) {
    ...
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}
""")
                    .font(.mono(.caption))
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .padding(.vertical, 4)
            }

            Section("Back Button Behavior") {
                ForEach(BackBehaviorItem.all) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.pattern).font(.subheadline).fontWeight(.medium)
                        Text(item.description).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Navigation Bar Behaviors") {
                NavigationLink("Large → Inline on scroll") {
                    LargeToInlineDemo()
                }
                NavigationLink("Transparent nav bar") {
                    TransparentNavBarDemo()
                }
            }
        }
        .navigationTitle("Navigation Patterns")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PushedView: View {
    let depth: Int

    var body: some View {
        List {
            NavigationLink("Push deeper (depth \(depth + 1))") {
                PushedView(depth: depth + 1)
            }
            Section("Current depth") {
                Text("Level \(depth)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("Level \(depth)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LargeToInlineDemo: View {
    var body: some View {
        List {
            ForEach(0..<30) { i in Text("Item \(i + 1)") }
        }
        .navigationTitle("Scroll down →")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TransparentNavBarDemo: View {
    var body: some View {
        ScrollView {
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.tint.opacity(0.6), .tint.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Content below the hero image")
                        .font(.title2).fontWeight(.semibold)
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 48)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct BackBehaviorItem: Identifiable {
    let id = UUID()
    let pattern: String
    let description: String

    static let all: [BackBehaviorItem] = [
        BackBehaviorItem(pattern: "Standard back button", description: "Auto-generated with previous screen title. Don't override unless title is too long."),
        BackBehaviorItem(pattern: ".navigationBackButtonHidden()", description: "Hide back button for forced flows (onboarding, payment). Always provide explicit dismiss."),
        BackBehaviorItem(pattern: ".navigationBarBackButtonHidden(true)", description: "Legacy API. Prefer the newer modifier above."),
        BackBehaviorItem(pattern: "Swipe-to-go-back", description: "Always supported unless back button is hidden. Don't disable unless UX requires it."),
    ]
}

struct TabPatternView: View {
    var body: some View {
        List {
            Section("Rules") {
                ForEach(TabPatternRule.all) { rule in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.title).font(.subheadline).fontWeight(.medium)
                        Text(rule.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Tab Bar Patterns")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TabPatternRule: Identifiable {
    let id = UUID()
    let title: String
    let detail: String

    static let all: [TabPatternRule] = [
        TabPatternRule(title: "Use tabs for top-level sections only", detail: "Don't nest tab bars. Each tab should be a distinct, parallel destination."),
        TabPatternRule(title: "Maximum 5 tabs", detail: "Overflow past 5 moves to a More tab. Prefer 3–5 for best usability."),
        TabPatternRule(title: "State is preserved per tab", detail: "Scroll position, navigation stack, and selection persist when switching tabs."),
        TabPatternRule(title: "Tapping active tab scrolls to top", detail: "Double-tapping an active tab should scroll its content to the top."),
        TabPatternRule(title: "Use filled icons for selected, outlined for unselected", detail: "SF Symbols provides filled and outlined variants for this purpose."),
    ]
}

#Preview {
    NavigationStack {
        NavigationPatternsView()
    }
}
