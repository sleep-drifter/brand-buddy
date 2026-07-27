import SwiftUI

// Live Activity anatomy — an interactive map of every surface a Live
// Activity renders on, built as in-app mockups (no widget extension needed).
// Two archetypes share the same six surfaces:
//
//   Order — Apple's canonical short-lived progress activity (coffee order):
//   ETA text, progress bar, waiting → preparing → ready.
//
//   Event — the ticket/check-in archetype (career fair, flight, concert):
//   a self-ticking countdown, check-in action with QR handoff, live
//   schedule info, and end-of-event feedback — plus alerting updates and
//   push-to-start, which only this archetype exercises.
//
// The countdown genuinely ticks: Text's timer date style is plain SwiftUI,
// and it's the same mechanism a real activity uses — the system renders
// time locally, no updates required.
//
// The real, on-device version (widget extension + ActivityKit driver) is a
// planned follow-up; this page is the design reference.

// MARK: - Archetypes

private enum Archetype: String, CaseIterable, Identifiable {
    case order = "Order", event = "Event"
    var id: String { rawValue }
}

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
}

private enum EventPhase: Int, CaseIterable, Identifiable {
    case upcoming, checkIn, live, ended
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .upcoming: "Upcoming"
        case .checkIn: "Check-in"
        case .live: "Live"
        case .ended: "Ended"
        }
    }
}

/// Everything a surface needs to render, computed from archetype + phase.
private struct SurfaceModel {
    var icon: String
    var iconTint: Color
    var title: String
    var place: String
    var status: String
    var statusTint: Color
    var phaseSymbol: String
    var progress: Double?
    var trailingText: String
    var countsDown = false
    var showsCheckIn = false
    var showsQR = false
    var nextUp: String?
    var showsRating = false
}

// MARK: - View

struct LiveActivityAnatomyView: View {
    @State private var archetype: Archetype = .order
    @State private var orderPhase: OrderPhase = .waiting
    @State private var eventPhase: EventPhase = .upcoming
    @State private var showLabels = true

    /// The mock event's door time — set once so the countdown really ticks.
    @State private var doorsOpen = Date.now.addingTimeInterval(87 * 60)

    var body: some View {
        List {
            Section {
                Text("One content state, six surfaces, two archetypes. Order is the progress-tracking pattern; Event is the ticket/check-in pattern — scrub the phases and watch the same surfaces adapt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Archetype", selection: $archetype) {
                    ForEach(Archetype.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                phasePicker
                Toggle("Region labels", isOn: $showLabels)
            }

            Section("Dynamic Island — compact") {
                compactIsland
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption(archetype == .event
                    ? "The trailing slot holds a **self-ticking countdown** — `Text`'s timer date style renders locally, so the island counts down with zero pushes and zero updates. This mock is genuinely ticking."
                    : "Two slots flank the sensor region: `compactLeading` and `compactTrailing`. Budget a glyph and one short value — this is the presentation people see most.")
            }

            Section("Dynamic Island — minimal") {
                minimalIsland
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("`minimal` appears when multiple Live Activities share the island — one circular slot beside the sensor. One glyph, ideally with state color.")
            }

            Section("Dynamic Island — expanded") {
                expandedIsland
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Four `DynamicIslandExpandedRegion`s: `.leading`, `.center`, `.trailing`, and full-width `.bottom`. In the Event archetype the bottom row changes job every phase — countdown, check-in action, schedule, then feedback.")
            }

            if archetype == .event {
                Section("Alerting update") {
                    alertMock
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    caption("Pass an `AlertConfiguration(title:body:sound:)` with `activity.update(_:alertConfiguration:)` and the island expands and buzzes — the gate-change / room-change moment. Use it sparingly; every alert interrupts.")
                }
            }

            Section("Lock Screen") {
                lockScreenBanner
                    .padding(.vertical, 6)
                caption(archetype == .event && currentModel.showsQR
                    ? "During check-in the banner carries the QR handoff and an intent button — tapping Check In runs a `LiveActivityIntent` without opening the app; tapping the card deep-links to the full ticket."
                    : "The banner view from `ActivityConfiguration`'s first closure. `activityBackgroundTint` sets the platter; keep contrast high — this renders over any wallpaper.")
            }

            Section("StandBy") {
                standByCard
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Same Lock Screen view scaled up on the nightstand. Check `showsWidgetContainerBackground` — when the system hides the platter, extend your own background.")
            }

            Section("Apple Watch — Smart Stack") {
                watchCard
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                caption("Opt in with `.supplementalActivityFamilies([.small])` and branch on `@Environment(\\.activityFamily)` — essentials only at this size.")
            }

            Section("How it ships") {
                VStack(alignment: .leading, spacing: 10) {
                    shipRow("Start", "`Activity.request(attributes:content:)` — static attributes plus the first `ContentState`. Gate on `ActivityAuthorizationInfo().areActivitiesEnabled`.")
                    shipRow("Push-to-start", "Events start remotely: the server lights up the Lock Screen morning-of via `Activity.pushToStartToken` — no app launch needed.")
                    shipRow("Countdowns", "`Text(timerInterval:)` and the `.timer` date style tick locally — a countdown needs no updates at all.")
                    shipRow("Update", "`activity.update(_:)` with a new state; set `staleDate` so outdated content is visually marked.")
                    shipRow("Alerts", "`activity.update(_:alertConfiguration:)` expands the island and plays a sound for the changes people must see — gate, room, time.")
                    shipRow("Broadcast", "Stadium-scale events update thousands of activities with one push via broadcast channels.")
                    shipRow("Check-in", "`Button(intent:)` with a `LiveActivityIntent` runs app code straight from the Lock Screen — the check-in tap.")
                    shipRow("End", "`activity.end(_:dismissalPolicy:)` — `.immediate`, `.default`, or `.after(date)` for a lingering final state (the feedback window).")
                    shipRow("Target", "All of the above renders from a widget extension target — this page mocks the surfaces so the design work can start first.")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Live Activity Anatomy")
        .animation(.snappy(duration: 0.25), value: orderPhase)
        .animation(.snappy(duration: 0.25), value: eventPhase)
        .animation(.snappy(duration: 0.25), value: archetype)
    }

    @ViewBuilder
    private var phasePicker: some View {
        switch archetype {
        case .order:
            Picker("Phase", selection: $orderPhase) {
                ForEach(OrderPhase.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        case .event:
            Picker("Phase", selection: $eventPhase) {
                ForEach(EventPhase.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Model

    private var currentModel: SurfaceModel {
        switch archetype {
        case .order:
            switch orderPhase {
            case .waiting:
                return SurfaceModel(icon: "cup.and.saucer.fill", iconTint: .brown,
                                    title: "Espresso", place: "Coffee Shop",
                                    status: "Order placed", statusTint: .orange,
                                    phaseSymbol: "hourglass", progress: 0.15,
                                    trailingText: "12 min")
            case .preparing:
                return SurfaceModel(icon: "cup.and.saucer.fill", iconTint: .brown,
                                    title: "Espresso", place: "Coffee Shop",
                                    status: "Being prepared", statusTint: .brown,
                                    phaseSymbol: "cup.and.saucer.fill", progress: 0.6,
                                    trailingText: "4 min")
            case .ready:
                return SurfaceModel(icon: "cup.and.saucer.fill", iconTint: .brown,
                                    title: "Espresso", place: "Coffee Shop",
                                    status: "Ready for pickup", statusTint: .green,
                                    phaseSymbol: "checkmark.circle.fill", progress: 1.0,
                                    trailingText: "Now")
            }
        case .event:
            switch eventPhase {
            case .upcoming:
                return SurfaceModel(icon: "briefcase.fill", iconTint: .cyan,
                                    title: "Spring Career Fair", place: "Rainey Hall",
                                    status: "Doors at 10:00", statusTint: .cyan,
                                    phaseSymbol: "clock", progress: nil,
                                    trailingText: "", countsDown: true)
            case .checkIn:
                return SurfaceModel(icon: "briefcase.fill", iconTint: .green,
                                    title: "Spring Career Fair", place: "Rainey Hall",
                                    status: "Check-in open · North lobby", statusTint: .green,
                                    phaseSymbol: "qrcode", progress: nil,
                                    trailingText: "Open",
                                    showsCheckIn: true, showsQR: true)
            case .live:
                return SurfaceModel(icon: "briefcase.fill", iconTint: .indigo,
                                    title: "Spring Career Fair", place: "Rainey Hall",
                                    status: "Happening now", statusTint: .indigo,
                                    phaseSymbol: "person.2.fill", progress: nil,
                                    trailingText: "Live",
                                    nextUp: "Up next: Acme Corp — Table 14 · 2:30")
            case .ended:
                return SurfaceModel(icon: "briefcase.fill", iconTint: .pink,
                                    title: "Spring Career Fair", place: "Rainey Hall",
                                    status: "Wrapped — how was it?", statusTint: .pink,
                                    phaseSymbol: "star.fill", progress: nil,
                                    trailingText: "Done", showsRating: true)
            }
        }
    }

    // MARK: - Compact island

    private var compactIsland: some View {
        let model = currentModel
        return HStack(spacing: 0) {
            Image(systemName: model.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(model.iconTint)
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

            trailingValue(model, font: .caption)
                .frame(width: 58)
                .regionLabel("compactTrailing", show: showLabels)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(.black, in: Capsule())
    }

    @ViewBuilder
    private func trailingValue(_ model: SurfaceModel, font: Font) -> some View {
        if model.countsDown {
            Text(doorsOpen, style: .timer)
                .font(font.monospacedDigit().weight(.semibold))
                .foregroundStyle(model.statusTint)
                .multilineTextAlignment(.trailing)
        } else {
            Text(model.trailingText)
                .font(font.monospacedDigit().weight(.semibold))
                .foregroundStyle(model.statusTint)
        }
    }

    // MARK: - Minimal island

    private var minimalIsland: some View {
        let model = currentModel
        return HStack(spacing: 6) {
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
                    Image(systemName: model.phaseSymbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(model.statusTint)
                )
                .regionLabel("minimal", show: showLabels)
        }
    }

    // MARK: - Expanded island

    private var expandedIsland: some View {
        let model = currentModel
        return VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: model.icon)
                        .foregroundStyle(model.iconTint)
                    Text(model.title)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .regionLabel(".leading", show: showLabels)

                Spacer(minLength: 8)

                Text(model.place)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .regionLabel(".center", show: showLabels)

                Spacer(minLength: 8)

                trailingValue(model, font: .footnote)
                    .regionLabel(".trailing", show: showLabels)
            }

            expandedBottom(model)
                .regionLabel(".bottom", show: showLabels)
        }
        .padding(14)
        .frame(maxWidth: 360)
        .background(.black, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private func expandedBottom(_ model: SurfaceModel) -> some View {
        if let progress = model.progress {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                ProgressView(value: progress)
                    .tint(model.statusTint)
            }
        } else if model.countsDown {
            HStack {
                Text("Doors open in")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(doorsOpen, style: .timer)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(model.statusTint)
            }
        } else if model.showsCheckIn {
            HStack(spacing: 10) {
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                mockButton("Check In", tint: .green)
            }
        } else if let nextUp = model.nextUp {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(model.statusTint)
                Text(nextUp)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
        } else if model.showsRating {
            HStack(spacing: 10) {
                Text("How was the fair?")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                mockRating
            }
        } else {
            Text(model.status)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - Alerting update mock

    private var alertMock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Room change")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("now")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text("Acme Corp moved: Table 14 → Hall C")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: 360)
        .background(.black, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.orange.opacity(0.7), lineWidth: 1.5)
        )
        .regionLabel("AlertConfiguration", show: showLabels)
    }

    // MARK: - Lock Screen

    private var lockScreenBanner: some View {
        activityCard
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
        activityCard
            .scaleEffect(1.06)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Watch

    private var watchCard: some View {
        let model = currentModel
        return HStack(spacing: 8) {
            Image(systemName: model.phaseSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(model.statusTint)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(model.status)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            trailingValue(model, font: .caption2)
        }
        .padding(10)
        .frame(width: 200)
        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .regionLabel("activityFamily == .small", show: showLabels)
    }

    // MARK: - Shared card

    private var activityCard: some View {
        let model = currentModel
        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: model.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(model.title) — \(model.place)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(model.nextUp ?? model.status)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                    if let progress = model.progress {
                        ProgressView(value: progress)
                            .tint(model.statusTint)
                    }
                }
                Spacer()
                if model.showsQR {
                    Image(systemName: "qrcode")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                } else {
                    trailingValue(model, font: .callout)
                }
            }
            if model.showsCheckIn {
                HStack {
                    Text("Show this at the North lobby desk")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    mockButton("Check In", tint: .green)
                }
            }
            if model.showsRating {
                HStack {
                    Text("Rate your day")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    mockRating
                }
            }
        }
        .padding(14)
        .background(cardTint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var cardTint: Color {
        archetype == .order ? .brown.opacity(0.55) : .black.opacity(0.45)
    }

    // MARK: - Helpers

    private func mockButton(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(tint.opacity(0.85), in: Capsule())
    }

    private var mockRating: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.thumbsdown.fill")
                .foregroundStyle(.white)
                .padding(7)
                .background(.red.opacity(0.8), in: Circle())
            Image(systemName: "hand.thumbsup.fill")
                .foregroundStyle(.white)
                .padding(7)
                .background(.green.opacity(0.8), in: Circle())
        }
        .font(.caption)
    }

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
