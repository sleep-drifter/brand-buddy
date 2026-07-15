import SwiftUI

struct SheetsModalsView: View {
    @State private var showHalfSheet = false
    @State private var showFullSheet = false
    @State private var showFullScreenCover = false
    @State private var showScrollSheet = false

    // Interactive detent playground
    @State private var showSheet = false
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var availableDetents: Set<PresentationDetent> = [.medium, .large]
    @State private var showDragIndicator = true
    @State private var customFraction: Double = 0.4
    @State private var customHeight: Double = 300

    private let phoneHeight: CGFloat = 200

    private var canvasSheetFraction: CGFloat {
        if selectedDetent == .medium { return 0.5 }
        if selectedDetent == .large { return 0.93 }
        if selectedDetent == .fraction(customFraction) { return customFraction }
        if selectedDetent == .height(customHeight) { return min(customHeight / 852, 0.93) }
        return 0.93
    }

    private var selectedDetentLabel: String {
        if selectedDetent == .medium { return ".medium" }
        if selectedDetent == .large { return ".large" }
        if selectedDetent == .fraction(customFraction) { return ".fraction(\(String(format: "%.2f", customFraction)))" }
        if selectedDetent == .height(customHeight) { return ".height(\(Int(customHeight)))" }
        return ".large"
    }

    private var detentCanvas: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                // App layer, dimmed behind the sheet
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.quaternary)
                        .frame(width: 56, height: 10)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.quaternary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.quaternary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.quaternary)
                        .frame(width: 72, height: 8)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(.secondarySystemGroupedBackground))
                .overlay(Color.black.opacity(0.25))

                // Sheet layer rising from the bottom
                VStack(spacing: 0) {
                    if showDragIndicator {
                        Capsule()
                            .fill(.tertiary)
                            .frame(width: 32, height: 4)
                            .padding(.top, 6)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: phoneHeight * canvasSheetFraction)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: -2)
                )
            }
            .frame(width: 140, height: phoneHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 1)
            )
            .animation(.spring(duration: 0.3), value: canvasSheetFraction)
            .animation(.spring(duration: 0.3), value: showDragIndicator)

            Text("\(selectedDetentLabel) — \(Int((canvasSheetFraction * 100).rounded()))% of screen")
                .font(.mono(.caption))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        List {
            Section("Presentation") {
                Picker("Selected detent", selection: $selectedDetent) {
                    Text(".medium").tag(PresentationDetent.medium)
                    Text(".large").tag(PresentationDetent.large)
                    Text(".fraction").tag(PresentationDetent.fraction(customFraction))
                    Text(".height").tag(PresentationDetent.height(customHeight))
                }
                .pickerStyle(.segmented)
                Toggle("Show drag indicator", isOn: $showDragIndicator)
            }

            Section("Active Detents") {
                Toggle(".medium", isOn: Binding(
                    get: { availableDetents.contains(.medium) },
                    set: { if $0 { availableDetents.insert(.medium) } else { availableDetents.remove(.medium) } }
                ))
                Toggle(".large", isOn: Binding(
                    get: { availableDetents.contains(.large) },
                    set: { if $0 { availableDetents.insert(.large) } else { availableDetents.remove(.large) } }
                ))
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(".fraction(\(customFraction, specifier: "%.2f"))", isOn: Binding(
                        get: { availableDetents.contains(.fraction(customFraction)) },
                        set: { if $0 { availableDetents.insert(.fraction(customFraction)) } else { availableDetents.remove(.fraction(customFraction)) } }
                    ))
                    Slider(value: $customFraction, in: 0.1...0.9)
                        .padding(.leading, 4)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(".height(\(Int(customHeight)))", isOn: Binding(
                        get: { availableDetents.contains(.height(customHeight)) },
                        set: { if $0 { availableDetents.insert(.height(customHeight)) } else { availableDetents.remove(.height(customHeight)) } }
                    ))
                    Slider(value: $customHeight, in: 100...700)
                        .padding(.leading, 4)
                }
            }

            Section("Interactive Detents") {
                Button("Show Interactive Sheet") { showSheet = true }
                Button("Show Scrolling Content Sheet") { showScrollSheet = true }
            }

            Section("Sheets") {
                Button("Present Sheet (medium)") { showHalfSheet = true }
                Button("Present Sheet (large)") { showFullSheet = true }
                Button("Scrolling content in sheet") { showScrollSheet = true }
            }

            Section("Full Screen") {
                Button("Full Screen Cover") { showFullScreenCover = true }
            }

            Section("Detent Reference") {
                ForEach(DetentReferenceItem.all) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.token)
                            .font(.mono(.subheadline))
                            .fontWeight(.medium)
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let example = item.example {
                            Text("e.g. \(example)")
                                .font(.caption)
                                .foregroundStyle(.tint)
                                .italic()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Sheet Modifiers") {
                ForEach(SheetModifierItem.all) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.modifier)
                            .font(.mono(.caption))
                            .foregroundStyle(.tint)
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .pinnedPreview(entry: "Sheets & Modals") {
            detentCanvas
        }
        .navigationTitle("Sheets & Modals")
        .onChange(of: customFraction) { oldValue, newValue in
            if selectedDetent == .fraction(oldValue) {
                selectedDetent = .fraction(newValue)
            }
        }
        .onChange(of: customHeight) { oldValue, newValue in
            if selectedDetent == .height(oldValue) {
                selectedDetent = .height(newValue)
            }
        }
        .sheet(isPresented: $showHalfSheet) {
            SampleSheetContent(title: "Medium Sheet")
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFullSheet) {
            SampleSheetContent(title: "Large Sheet")
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSheet) {
            SheetDetentsDemo(
                selectedDetent: $selectedDetent,
                availableDetents: availableDetents.isEmpty ? [.large] : availableDetents,
                showDragIndicator: showDragIndicator
            )
        }
        .fullScreenCover(isPresented: $showFullScreenCover) {
            SampleSheetContent(title: "Full Screen Cover", isFullScreen: true)
        }
        .sheet(isPresented: $showScrollSheet) {
            ScrollingSheetDemo(showDragIndicator: showDragIndicator)
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
    private enum ToastType: String, CaseIterable, Identifiable {
        case success = "Success"
        case warning = "Warning"
        case error = "Error"
        case info = "Info"

        var id: Self { self }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            case .info: return "info.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
    }

    private enum ToastPosition: String, CaseIterable, Identifiable {
        case top = "Top"
        case bottom = "Bottom"

        var id: Self { self }

        var edge: Edge { self == .top ? .top : .bottom }
        var alignment: Alignment { self == .top ? .top : .bottom }
    }

    @State private var toastType: ToastType = .success
    @State private var message = "Item saved successfully"
    @State private var position: ToastPosition = .top
    @State private var autoDismiss = true
    @State private var duration: Double = 2.5
    @State private var isToastVisible = false
    @State private var dismissTask: Task<Void, Never>?

    private var toastCanvas: some View {
        VStack(spacing: 10) {
            ZStack(alignment: position.alignment) {
                Color(.secondarySystemGroupedBackground)

                VStack(spacing: 16) {
                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(.quaternary)
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(.quaternary)
                                    .frame(width: 110, height: 10)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(.quaternary.opacity(0.6))
                                    .frame(width: 170, height: 10)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isToastVisible {
                    toastPill
                        .padding(12)
                        .transition(.move(edge: position.edge).combined(with: .opacity))
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
            .animation(.spring(duration: 0.3), value: position)
            .animation(.spring(duration: 0.3), value: toastType)

            Button {
                if isToastVisible {
                    hideToast()
                } else {
                    showToast()
                }
            } label: {
                Label(isToastVisible ? "Hide toast" : "Show toast", systemImage: "bell.badge")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    var body: some View {
        List {
            Section("Toast") {
                Picker("Type", selection: $toastType) {
                    ForEach(ToastType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Message", text: $message)
                Picker("Position", selection: $position) {
                    ForEach(ToastPosition.allCases) { position in
                        Text(position.rawValue).tag(position)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Dismissal") {
                Toggle("Auto-dismiss", isOn: $autoDismiss.animation(.spring(duration: 0.3)))
                if autoDismiss {
                    LabeledContent("duration: \(duration, specifier: "%.1f")s") {
                        Slider(value: $duration, in: 1...5, step: 0.5)
                    }
                }
            }

            Section("When to Use") {
                Text("iOS doesn't have a native toast/banner component for in-app use. Build one with an overlay, a spring transition, and an auto-dismiss timer — and reserve it for passive status that requires no action.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .pinnedPreview(entry: "Toasts & Banners") {
            toastCanvas
        }
        .navigationTitle("Toasts & Banners")
        .onChange(of: autoDismiss) { _, isOn in
            if !isOn { dismissTask?.cancel() }
        }
    }

    private var toastPill: some View {
        HStack(spacing: 10) {
            Image(systemName: toastType.icon)
                .foregroundStyle(toastType.tint)
            Text(message.isEmpty ? "Toast message" : message)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .overlay(Capsule().fill(toastType.tint.opacity(0.15)))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        )
    }

    private func showToast() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
            isToastVisible = true
        }
        guard autoDismiss else { return }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            hideToast()
        }
    }

    private func hideToast() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
            isToastVisible = false
        }
    }
}

#Preview {
    NavigationStack {
        SheetsModalsView()
    }
    .environmentObject(PinsStore())
}
