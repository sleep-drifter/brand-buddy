import SwiftUI

struct PatternsTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Navigation") {
                    NavigationLink { NavigationPatternsView() } label: {
                        Label("Navigation Patterns", systemImage: "arrow.triangle.turn.up.right.diamond")
                    }
                    NavigationLink { TabPatternView() } label: {
                        Label("Tab Bar Patterns", systemImage: "rectangle.bottomthird.inset.filled")
                    }
                }
                Section("Presentation") {
                    NavigationLink { ModalPatternsView() } label: {
                        Label("Modal Patterns", systemImage: "rectangle.topthird.inset.filled")
                    }
                    NavigationLink { SheetFlowsView() } label: {
                        Label("Sheet Flows", systemImage: "arrow.up.and.down.square")
                    }
                }
                Section("Input & Search") {
                    NavigationLink { SearchPatternView() } label: {
                        Label("Search Patterns", systemImage: "magnifyingglass")
                    }
                    NavigationLink { FormPatternView() } label: {
                        Label("Form Patterns", systemImage: "list.clipboard")
                    }
                }
                Section("Content") {
                    NavigationLink { EmptyStatesView() } label: {
                        Label("Empty States", systemImage: "tray")
                    }
                    NavigationLink { LoadingStatesView() } label: {
                        Label("Loading States", systemImage: "progress.indicator")
                    }
                    NavigationLink { ErrorStatesView() } label: {
                        Label("Error States", systemImage: "exclamationmark.triangle")
                    }
                }
                Section("Settings") {
                    NavigationLink { SettingsPatternView() } label: {
                        Label("Settings Patterns", systemImage: "gear")
                    }
                }
                Section("Onboarding") {
                    NavigationLink { OnboardingView() } label: {
                        Label("Onboarding Flows", systemImage: "hand.wave")
                    }
                }
            }
            .navigationTitle("Patterns")
        }
    }
}

#Preview {
    PatternsTab()
}
