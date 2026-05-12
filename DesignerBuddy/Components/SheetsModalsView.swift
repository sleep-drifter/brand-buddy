import SwiftUI

struct SheetsModalsView: View {
    @State private var showSheet = false
    @State private var showHalfSheet = false
    @State private var showFullSheet = false
    @State private var showFullScreenCover = false
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        List {
            Section("Sheets") {
                Button("Present Sheet (medium)") { showHalfSheet = true }
                Button("Present Sheet (large)") { showFullSheet = true }
                Button("Present Sheet (interactive detents)") { showSheet = true }
            }
            Section("Full Screen") {
                Button("Full Screen Cover") { showFullScreenCover = true }
            }
            Section("Detent Reference") {
                ForEach(DetentInfo.all) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.token)
                            .font(.mono(.subheadline))
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Sheets & Modals")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showHalfSheet) {
            SampleSheetContent(title: "Medium Sheet")
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFullSheet) {
            SampleSheetContent(title: "Large Sheet")
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSheet) {
            SampleSheetContent(title: "Interactive Detents")
                .presentationDetents([.medium, .large], selection: $detent)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFullScreenCover) {
            SampleSheetContent(title: "Full Screen Cover", isFullScreen: true)
        }
    }
}

struct SampleSheetContent: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    var isFullScreen: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.portrait.bottomhalf.inset.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("This is the sheet content area. Drag to resize or dismiss.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DetentInfo: Identifiable {
    let id = UUID()
    let token: String
    let description: String

    static let all: [DetentInfo] = [
        DetentInfo(token: ".medium", description: "Approximately half the screen height"),
        DetentInfo(token: ".large", description: "Full available height (default)"),
        DetentInfo(token: ".fraction(0.3)", description: "Custom fraction of screen height"),
        DetentInfo(token: ".height(300)", description: "Fixed point height"),
        DetentInfo(token: "Custom (Context)", description: "Height derived from content or environment"),
    ]
}

struct ActionSheetsView: View {
    @State private var showConfirmation = false
    @State private var showDestructive = false

    var body: some View {
        List {
            Section("Confirmation Dialog") {
                Button("Show confirmation dialog") { showConfirmation = true }
                Button("Show destructive dialog") { showDestructive = true }
            }
            Section("When to Use") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use .confirmationDialog() for 3+ options or when you need a title.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Use Alert for 1–2 options, especially critical confirmations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Action Sheets")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Choose an action", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Save to Photos") {}
            Button("Share") {}
            Button("Copy") {}
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete this item?", isPresented: $showDestructive, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct PopoversView: View {
    @State private var showPopover = false

    var body: some View {
        List {
            Section {
                Button("Show popover") { showPopover = true }
                    .popover(isPresented: $showPopover) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Popover Title")
                                .font(.headline)
                            Text("Popovers appear as floating panels, anchored to their source view.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(minWidth: 240)
                    }
            }
            Section("Usage") {
                Text("On iPhone, popovers present as sheets. On iPad, they show as floating panels.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("Popovers")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ToastsView: View {
    var body: some View {
        List {
            Section {
                Text("iOS doesn't have a native toast/banner component for in-app use. Common patterns:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            Section("Patterns") {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Item saved successfully")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Connection lost. Retrying…")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Toasts & Banners")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SheetsModalsView()
    }
}
