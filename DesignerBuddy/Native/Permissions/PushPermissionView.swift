import SwiftUI
import UserNotifications

// MARK: - Main View

struct PushPermissionView: View {

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var notifTitle: String = "Test Notification"
    @State private var notifBody: String = "This is a scheduled local notification from the push demo."
    @State private var showBadge: Bool = true
    @State private var badgeCount: Int = 1
    @State private var interruptionLevel: BannerInterruptionLevel = .active
    @State private var delaySeconds: Int = 5
    @State private var isScheduling: Bool = false
    @State private var countdown: Int? = nil
    @State private var countdownTimer: Timer? = nil

    let delayOptions = [5, 10, 30]

    var body: some View {
        List {

            // MARK: Banner Canvas
            Section {
                VStack(spacing: 24) {
                    bannerCanvas
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(duration: 0.3), value: canvasState)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // MARK: Banner Content Section
            Section {
                TextField("Notification title", text: $notifTitle)

                TextField("Notification body", text: $notifBody, axis: .vertical)
                    .lineLimit(1...3)

                Toggle("Badge", isOn: $showBadge)

                Stepper("Count: \(badgeCount)", value: $badgeCount, in: 1...99)
                    .disabled(!showBadge)

                VStack(alignment: .leading, spacing: 6) {
                    Picker("Interruption level", selection: $interruptionLevel) {
                        ForEach(BannerInterruptionLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(interruptionLevel.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Banner Content")
            } footer: {
                Text("Drives the preview above — title, body, and badge are also used when scheduling below.")
            }

            // MARK: Authorization Section
            Section("Authorization") {
                authStatusCard
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                if authStatus == .notDetermined {
                    Button {
                        requestAuthorization()
                    } label: {
                        Label("Request Permission", systemImage: "bell.badge")
                            .fontWeight(.semibold)
                    }
                }

                if authStatus == .denied {
                    deniedRecoveryRow
                }
            }

            // MARK: Schedule Section
            Section {
                Picker("Delay", selection: $delaySeconds) {
                    ForEach(delayOptions, id: \.self) { s in
                        Text("\(s) seconds").tag(s)
                    }
                }
                .disabled(authStatus != .authorized)

                Button {
                    scheduleNotification()
                } label: {
                    if isScheduling {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Scheduling…")
                        }
                    } else {
                        Label("Schedule Notification", systemImage: "clock.badge")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(authStatus != .authorized || isScheduling || notifTitle.isEmpty)

                if let remaining = countdown {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .foregroundStyle(.tint)
                            .font(.caption)
                        Text("Notification in \(remaining)s")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                            .contentTransition(.numericText())
                            .animation(.default, value: remaining)
                        Spacer()
                        Text("Lock the screen or background the app to see it arrive.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            } header: {
                Text("Schedule a Local Notification")
            } footer: {
                if authStatus != .authorized {
                    Text("Grant notification permission above to enable scheduling.")
                }
            }

            // MARK: Content Types Reference
            Section("Notification Content Types") {
                contentTypeRow(
                    property: ".title",
                    example: "\"Your order has shipped\"",
                    detail: "Bold, largest text. Always required — the OS may truncate it.",
                    inPreview: true
                )
                contentTypeRow(
                    property: ".subtitle",
                    example: "\"2 items · Est. Wednesday\"",
                    detail: "Smaller line below the title. Optional — skip if it repeats the title."
                )
                contentTypeRow(
                    property: ".body",
                    example: "\"Tap to track your delivery in real-time.\"",
                    detail: "Supporting detail. Only shown in expanded or banner view.",
                    inPreview: true
                )
                contentTypeRow(
                    property: ".badge",
                    example: "3",
                    detail: "App icon badge count. Set to 0 to clear. Requires .badge auth option.",
                    inPreview: true
                )
                contentTypeRow(
                    property: ".sound",
                    example: ".default / .defaultCritical",
                    detail: ".default respects silent mode. .defaultCritical plays through DND and silent — requires a special entitlement."
                )
                contentTypeRow(
                    property: ".interruptionLevel",
                    example: ".passive / .active / .timeSensitive / .critical",
                    detail: ".passive — silently added to notification list. .active — standard. .timeSensitive — breaks through Focus. .critical — bypasses all. Each requires escalating justification.",
                    inPreview: true
                )
            }
        }
        .navigationTitle("Push Notifications")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { checkStatus() }
    }

    private var canvasState: [AnyHashable] {
        [notifTitle, notifBody, showBadge, badgeCount, interruptionLevel]
    }

    // MARK: - Banner Canvas

    private var bannerCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.7), Color.purple.opacity(0.5), Color.cyan.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 18) {
                Text("9:41")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                bannerPreview
            }
            .padding(20)
        }
        .frame(height: 280)
    }

    private var bannerPreview: some View {
        HStack(alignment: .top, spacing: 12) {
            // App icon
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                    )

                if showBadge {
                    Text("\(badgeCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.red))
                        .offset(x: 8, y: -6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                // App name + time row
                HStack {
                    Text("Designer Buddy")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("now")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(notifTitle.isEmpty ? "Notification title" : notifTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(notifBody.isEmpty ? "Notification body" : notifBody)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            if let accent = interruptionLevel.accent {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(accent.opacity(0.7), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Auth Status Card

    @ViewBuilder
    private var authStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Notification Permission")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            Spacer()
        }
    }

    // MARK: - Denied Recovery Row

    @ViewBuilder
    private var deniedRecoveryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications are blocked")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("Go to **Settings → Notifications → Designer Buddy** and turn on \"Allow Notifications\".")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Go to Settings", systemImage: "gear")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Content Type Row

    @ViewBuilder
    private func contentTypeRow(property: String, example: String, detail: String, inPreview: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(property)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                Text(example)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if inPreview {
                    Spacer(minLength: 8)
                    Text("in preview")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.tint.opacity(0.12)))
                }
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Computed Status Properties

    private var statusColor: Color {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied:                               return .red
        default:                                    return .secondary
        }
    }

    private var statusIcon: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "bell.fill"
        case .denied:                               return "bell.slash.fill"
        default:                                    return "bell"
        }
    }

    private var statusLabel: String {
        switch authStatus {
        case .authorized:   return "Authorized — all options available"
        case .provisional:  return "Provisional — quiet delivery, no banner"
        case .ephemeral:    return "Ephemeral — App Clip temporary grant"
        case .denied:       return "Denied — user must go to Settings"
        case .notDetermined: return "Not Determined — not yet requested"
        @unknown default:   return "Unknown"
        }
    }

    // MARK: - Actions

    private func checkStatus() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authStatus = settings.authorizationStatus
        }
    }

    private func requestAuthorization() {
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                _ = granted
            } catch {
                // Permission request failed (unlikely on device)
            }
            checkStatus()
        }
    }

    private func scheduleNotification() {
        isScheduling = true
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdown = nil

        let content = UNMutableNotificationContent()
        content.title = notifTitle
        content.subtitle = "Designer Buddy Demo"
        content.body = notifBody
        content.sound = .default
        if showBadge {
            content.badge = NSNumber(value: badgeCount)
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delaySeconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                isScheduling = false
                if error == nil {
                    startCountdown(from: delaySeconds)
                }
            }
        }
    }

    private func startCountdown(from seconds: Int) {
        countdown = seconds
        var remaining = seconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            remaining -= 1
            withAnimation { countdown = max(0, remaining) }
            if remaining <= 0 {
                timer.invalidate()
                countdownTimer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { countdown = nil }
                }
            }
        }
    }
}

// MARK: - Interruption Level

private enum BannerInterruptionLevel: String, CaseIterable, Identifiable {
    case passive = "Passive"
    case active = "Active"
    case timeSensitive = "Time Sensitive"
    case critical = "Critical"

    var id: Self { self }

    var caption: String {
        switch self {
        case .passive:       return "Silently added to Notification Center — no sound, no banner, no screen wake."
        case .active:        return "Default. Plays sound and lights up the screen, but respects Focus."
        case .timeSensitive: return "Breaks through Focus and scheduled delivery. Requires the Time Sensitive entitlement."
        case .critical:      return "Bypasses Focus, Do Not Disturb, and the mute switch. Requires an Apple-granted entitlement."
        }
    }

    var accent: Color? {
        switch self {
        case .timeSensitive: return .orange
        case .critical:      return .red
        default:             return nil
        }
    }
}

#Preview {
    NavigationStack {
        PushPermissionView()
    }
}
