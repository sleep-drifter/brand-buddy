import SwiftUI

struct PatternsTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Navigation") {
                    NavigationLink("Navigation Patterns") { NavigationPatternsView() }
                    NavigationLink("Tab Bar Patterns") { TabPatternView() }
                }
                Section("Presentation") {
                    NavigationLink("Modal Patterns") { ModalPatternsView() }
                    NavigationLink("Sheet Flows") { SheetFlowsView() }
                }
                Section("Input & Search") {
                    NavigationLink("Search Patterns") { SearchPatternView() }
                    NavigationLink("Form Patterns") { FormPatternView() }
                }
                Section("Content") {
                    NavigationLink("Empty States") { EmptyStatesView() }
                    NavigationLink("Loading States") { LoadingStatesView() }
                    NavigationLink("Error States") { ErrorStatesView() }
                }
                Section("Settings") {
                    NavigationLink("Settings Patterns") { SettingsPatternView() }
                }
                Section("Onboarding") {
                    NavigationLink("Onboarding Flows") { OnboardingView() }
                }
            }
            .navigationTitle("Patterns")
        }
    }
}

#Preview {
    PatternsTab()
}
