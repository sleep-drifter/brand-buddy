import SwiftUI

// Live Activity anatomy — an interactive map of every surface a Live
// Activity renders on, built as in-app mockups (no widget extension needed).
// A sample coffee order walks waiting → preparing → ready so you can see how
// each surface should respond to the same content state. Region labels
// carry the ActivityKit API names for each slot.
//
// The real, on-device version (widget extension + ActivityKit driver) is a
// planned follow-up; this page is the design reference.

private enum OrderPhase: Int, CaseIterable, Identifiable {
    case waiting, preparing, ready

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .waiting: "Waiting"
        case .preparing: "Preparing"
        case .ready: "Ready"
        }
    }

    var status: String {
        switch self {
        case .waiting: "Order placed"
        case .preparing: "Being prepared"
        case .ready: "Ready for pickup"
        }
    }

    var symbol: String {
        switch self {
        case .waiting: "hourglass"
        case .preparing: "cup.and.saucer.fill"
        case .ready: "checkmark.circle.fill"
        }
    }

    var eta: String {
        switch self {
        case .waiting: "12 min"
        case .preparing: "4 min"
        case .ready: "Now"
        }
    }

    var progress: Double {
        switch self {
        case .waiting: 0.15
        case .preparing: 0.6
        case .ready: 1.0
        }
    }

    var tint: Color {
        switch self {
        case .waiting: .orange
        case .preparing: .brown
        case .ready: .green
        }
    }
}

struct LiveActivityAnatomyView: View {
    @State private var phase: OrderPhase = .waiting
    @State private var showLabels = true

    var body: some View {
        List {
            Section {
                Text("One content state, six surfaces. Scrub the order phase and watch how the same data should adapt to each presentation — region labels show the ActivityKit slot names.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Phase", selection: $phase) {
                    ForEach(OrderPhase.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Region labels", isOn: $showLabels)
            }

            Section("Dynamic Island — compact") {
                compactIsland
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Two slots flank the sensor region: `compactLeading` and `compactTrailing`. Budget a glyph and one short value — this is the presentation people see most, so it earns the most design attention.")
            }

            Section("Dynamic Island — minimal") {
                minimalIsland
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("`minimal` appears when multiple Live Activities share the island — one circular slot, detached beside the sensor. One glyph, ideally with state color.")
            }

            Section("Dynamic Island — expanded") {
                expandedIsland
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Long-press the island and four `DynamicIslandExpandedRegion`s compose the layout: `.leading`, `.center`, `.trailing`, and a full-width `.bottom`. Regions size to content; the bottom row is where progress and actions live.")
            }

            Section("Lock Screen") {
                lockScreenBanner
                    .padding(.vertical, 6)
                caption("The banner view from `ActivityConfiguration`'s first closure. `activityBackgroundTint` sets the platter color; keep contrast high — this renders over any wallpaper, and on Always-On displays it dims further.")
            }

            Section("StandBy") {
                standByCard
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Same Lock Screen view scaled up on the nightstand. Check `showsWidgetContainerBackground` — when the system hides the platter, extend your own background so the layout doesn't float.")
            }

            Section("Apple Watch — Smart Stack") {
                watchCard
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Opt in with `.supplementalActivityFamilies([.small])` and branch on `@Environment(\\.activityFamily)` — the small family gets a denser layout with the essentials only.")
            }

            Section("How it ships") {
                VStack(alignment: .leading, spacing: 10) {
                    shipRow("Start", "`Activity.request(attributes:content:)` — static attributes plus the first `ContentState`. Gate on `ActivityAuthorizationInfo().areActivitiesEnabled`.")
                    shipRow("Update", "`activity.update(_:)` with a new state; set `staleDate` so the system can visually mark outdated content.")
                    shipRow("End", "`activity.end(_:dismissalPolicy:)` — `.immediate`, `.default`, or `.after(date)` for a lingering final state.")
                    shipRow("Buttons", "`Button(intent:)` with a `LiveActivityIntent` runs app code straight from the island or Lock Screen.")
                    shipRow("Push", "Remote updates use the ActivityKit push entitlement and per-activity tokens — server required.")
                    shipRow("Target", "All of the above renders from a widget extension target — this page mocks the surfaces so the design work can start first.")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Live Activity Anatomy")
        .animation(.snappy(duration: 0.25), value: phase)
    }

    // MARK: - Compact island

    private var compactIsland: some View {
        HStack(spacing: 0) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.brown)
                .frame(width: 34)
                .regionLabel("compactLeading", show: showLabels)

            Capsule()
                .fill(.black)
                .frame(width: 78, height: 24)
                .overlay(
                    Text("sensors")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.25))
                )

            Text(phase.eta)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(phase.tint)
                .frame(width: 44)
                .regionLabel("compactTrailing", show: showLabels)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(.black, in: Capsule())
    }

    // MARK: - Minimal island

    private var minimalIsland: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(.black)
                .frame(width: 110, height: 36)
                .overlay(
                    Text("other activity")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                )
            Circle()
                .fill(.black)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: phase.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(phase.tint)
                )
                .regionLabel("minimal", show: showLabels)
        }
    }

    // MARK: - Expanded island

    private var expandedIsland: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(.brown)
                    Text("Espresso")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                }
                .regionLabel(".leading", show: showLabels)

                Spacer()

                Text("Coffee Shop")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .regionLabel(".center", show: showLabels)

                Spacer()

                Text(phase.eta)
                    .font(.footnote.monospacedDigit().weight(.semibold))
                    .foregroundStyle(phase.tint)
                    .regionLabel(".trailing", show: showLabels)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(phase.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                ProgressView(value: phase.progress)
                    .tint(phase.tint)
            }
            .regionLabel(".bottom", show: showLabels)
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(.black, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: - Lock Screen

    private var lockScreenBanner: some View {
        activityCard(compact: false)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [.indigo, .purple, .pink],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
    }

    // MARK: - StandBy

    private var standByCard: some View {
        activityCard(compact: false)
            .scaleEffect(1.06)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Watch

    private var watchCard: some View {
        HStack(spacing: 8) {
            Image(systemName: phase.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(phase.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Espresso")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text(phase.status)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Text(phase.eta)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(phase.tint)
        }
        .padding(10)
        .frame(width: 190)
        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .regionLabel("activityFamily == .small", show: showLabels)
    }

    // MARK: - Shared card

    private func activityCard(compact: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 3) {
                Text("Espresso — Coffee Shop")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(phase.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                ProgressView(value: phase.progress)
                    .tint(phase.tint)
            }
            Spacer()
            Text(phase.eta)
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(phase.tint)
        }
        .padding(14)
        .background(.brown.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Helpers

    private func caption(_ text: String) -> some View {
        Text(.init(text))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func shipRow(_ token: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(token).font(.mono(.caption)).foregroundStyle(.primary)
            Text(.init(note)).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// Dashed annotation box with the ActivityKit region name, toggled by the
// page's labels switch.
private struct RegionLabel: ViewModifier {
    let name: String
    let show: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if show {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.cyan.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .padding(-3)
                }
            }
            .overlay(alignment: .bottom) {
                if show {
                    Text(name)
                        .font(.system(size: 7.5, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(.cyan, in: Capsule())
                        .fixedSize()
                        .offset(y: 13)
                }
            }
    }
}

private extension View {
    func regionLabel(_ name: String, show: Bool) -> some View {
        modifier(RegionLabel(name: name, show: show))
    }
}

#Preview {
    NavigationStack { LiveActivityAnatomyView() }
        .environmentObject(PinsStore())
}
