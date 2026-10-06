import SwiftUI
import UIKit
import UserNotifications

// Notification anatomy — the design side of notifications, as a sibling to
// Live Activity Anatomy: banner regions, attachments, grouping and
// summaries, and interruption levels, built as in-app mockups. A "Live
// demos" section schedules real local notifications (5s delay) so each
// concept can also be seen on the actual system surface — background the
// app after tapping fire.

struct NotificationAnatomyView: View {

    @State private var showLabels = true

    private enum AttachmentStyle: String, CaseIterable {
        case none = "None", thumbnail = "Thumbnail", expanded = "Expanded"
    }
    @State private var attachmentStyle: AttachmentStyle = .thumbnail

    @State private var stackedGroup = true
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("A notification earns a second of attention — the design question is whether that second is enough to understand *what happened* and *whether to act*. These mockups map every region the system gives you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Banner anatomy ─────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Banner Anatomy", tag: "Regions")) {
                MockBanner(
                    title: "Design review at 3 PM",
                    subtitle: "Buddy Workspace",
                    message: "Nia moved the review up an hour — new deck is attached, same room.",
                    showThumbnail: false,
                    labels: showLabels
                )
                .padding(.vertical, 6)

                if showLabels {
                    legendRow(color: .red,    text: "App icon — always yours, never content")
                    legendRow(color: .blue,   text: "Title — the event, ~4 words")
                    legendRow(color: .purple, text: "Subtitle — optional source or context line")
                    legendRow(color: .green,  text: "Body — the detail; ~2 lines before truncation")
                    legendRow(color: .orange, text: "Timestamp — system-supplied, relative")
                }
                Toggle("Show region labels", isOn: $showLabels)
                RefCaption("UNMutableNotificationContent: title · subtitle · body")
                HIGNoteRow("Write the title as the event (\"Order shipped\"), not the app's name — the icon already says who's talking. Front-load the body: the second line may never be seen.")
            }

            // ── Attachments ────────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Attachments", tag: "Media")) {
                Group {
                    switch attachmentStyle {
                    case .none:
                        MockBanner(
                            title: "New photo shared",
                            message: "Kai added 1 photo to \"Studio Shoot\".",
                            showThumbnail: false, labels: false)
                    case .thumbnail:
                        MockBanner(
                            title: "New photo shared",
                            message: "Kai added 1 photo to \"Studio Shoot\".",
                            showThumbnail: true, labels: false)
                    case .expanded:
                        VStack(spacing: 0) {
                            MockBanner(
                                title: "New photo shared",
                                message: "Kai added 1 photo to \"Studio Shoot\".",
                                showThumbnail: false, labels: false,
                                squaredBottom: true)
                            LinearGradient(colors: [.blue, .purple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                                .frame(height: 150)
                                .overlay {
                                    Image(systemName: "photo.artframe")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .clipShape(UnevenRoundedRectangle(
                                    bottomLeadingRadius: 20, bottomTrailingRadius: 20))
                        }
                    }
                }
                .padding(.vertical, 6)

                Picker("Attachment", selection: $attachmentStyle) {
                    ForEach(AttachmentStyle.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                RefCaption("UNNotificationAttachment — collapsed thumbnail, expanded on press")
                HIGNoteRow("The thumbnail rides the trailing edge of the collapsed banner; a long-press expands it to full media. Attach media that *is* the message — a photo, a chart — not decoration.")
            }

            // ── Grouping & summaries ───────────────────────────────────────
            Section(header: SectionTagHeader(title: "Grouping & Summaries", tag: "threadIdentifier")) {
                Group {
                    if stackedGroup {
                        ZStack(alignment: .top) {
                            stackCard(scale: 0.88, offset: 18)
                            stackCard(scale: 0.94, offset: 9)
                            MockBanner(
                                title: "Mina: \"ship it 🚀\"",
                                message: "#design-crit · 3 new messages",
                                showThumbnail: false, labels: false)
                        }
                        .padding(.bottom, 18)
                    } else {
                        VStack(spacing: 8) {
                            MockBanner(title: "Mina: \"ship it 🚀\"",
                                       message: "#design-crit",
                                       showThumbnail: false, labels: false)
                            MockBanner(title: "Theo attached Final-v3.sketch",
                                       message: "#design-crit",
                                       showThumbnail: false, labels: false)
                            MockBanner(title: "Mina started a thread",
                                       message: "#design-crit",
                                       showThumbnail: false, labels: false)
                        }
                    }
                }
                .padding(.vertical, 6)

                Toggle("Collapsed stack", isOn: $stackedGroup)
                RefCaption("content.threadIdentifier groups · summary shows \"3 more…\"")
                HIGNoteRow("Group by conversation or task, not by app — the system already groups per app as a fallback. A good thread turns six pings into one stack with one decision.")
            }

            // ── Interruption levels ────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Interruption Levels", tag: "iOS 15+")) {
                levelRow(icon: "moon.zzz.fill", tint: .indigo, name: "Passive",
                         detail: "No sound, no wake, waits in Notification Center. Ambient info: a show you follow got a new episode.")
                levelRow(icon: "app.badge", tint: .blue, name: "Active (default)",
                         detail: "Sound and banner, respects Focus. Everyday events: a message, a completed export.")
                levelRow(icon: "bell.and.waves.left.and.right", tint: .orange, name: "Time Sensitive",
                         detail: "Breaks through Focus and stays on the Lock Screen longer. Needs the Time Sensitive entitlement and genuine urgency: a ride arriving, a security alert.")
                levelRow(icon: "bolt.fill", tint: .red, name: "Critical",
                         detail: "Sounds even when muted. Apple-granted entitlement only — health and safety territory.")
                RefCaption("content.interruptionLevel = .passive / .active / .timeSensitive / .critical")
                HIGNoteRow("Pick the lowest level that still serves the person. Misusing Time Sensitive is how apps get their notifications turned off entirely.")
            }

            // ── Live demos ─────────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Live Demos", tag: "5s delay")) {
                LabeledContent("Permission", value: statusLabel)
                if authStatus == .notDetermined {
                    Button("Request permission") { requestPermission() }
                }
                Button("Fire basic banner") {
                    fire(title: "Design review at 3 PM",
                         body: "Nia moved the review up an hour — same room.")
                }
                Button("Fire with image attachment") {
                    fire(title: "New photo shared",
                         body: "Kai added 1 photo to \"Studio Shoot\".",
                         attachImage: true)
                }
                Button("Fire grouped thread (×3)") {
                    fire(title: "Mina: \"ship it 🚀\"", body: "#design-crit",
                         thread: "design-crit", delay: 5)
                    fire(title: "Theo attached Final-v3.sketch", body: "#design-crit",
                         thread: "design-crit", delay: 6)
                    fire(title: "Mina started a thread", body: "#design-crit",
                         thread: "design-crit", delay: 7)
                }
                Button("Fire time-sensitive") {
                    fire(title: "Your ride is arriving",
                         body: "Silver sedan · 1 minute away.",
                         level: .timeSensitive)
                }
                RefCaption("background the app after tapping — foreground apps suppress banners")
                HIGNoteRow("Time Sensitive elevates only with the capability enabled in Signing & Capabilities; without it the system quietly treats it as Active.")
            }
            .disabled(authStatus == .denied)

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                DoDontRow(good: true,  text: "Make every notification actionable or informative on its own — assume it's read on a locked phone, out of context.")
                DoDontRow(good: false, text: "Don't make notifications the only path to content; everything must also be reachable in the app.")
                DoDontRow(good: false, text: "Don't send marketing as Time Sensitive — it's grounds for revocation, and people punish it with the permission switch.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                CodeBlockRow(code: """
                    let content = UNMutableNotificationContent()
                    content.title = "Design review at 3 PM"
                    content.body = "Nia moved the review up an hour."
                    content.threadIdentifier = "design-crit"
                    content.interruptionLevel = .timeSensitive
                    content.sound = .default

                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: UNTimeIntervalNotificationTrigger(
                            timeInterval: 5, repeats: false))
                    try await UNUserNotificationCenter.current().add(request)
                    """)
            }
        }
        .navigationTitle("Notification Anatomy")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatus() }
    }

    // MARK: - Live notification plumbing

    private var statusLabel: String {
        switch authStatus {
        case .notDetermined: return "Not requested"
        case .denied:        return "Denied — enable in Settings"
        case .authorized:    return "Authorized"
        case .provisional:   return "Provisional (quiet)"
        case .ephemeral:     return "Ephemeral"
        @unknown default:    return "Unknown"
        }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus
    }

    private func requestPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
        }
    }

    private func fire(title: String, body: String, thread: String? = nil,
                      level: UNNotificationInterruptionLevel = .active,
                      attachImage: Bool = false, delay: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = level
        if let thread { content.threadIdentifier = thread }
        if attachImage, let attachment = makeAttachment() {
            content.attachments = [attachment]
        }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }

    /// Renders a small gradient PNG to the temp directory so the attachment
    /// demo needs no bundled asset.
    private func makeAttachment() -> UNNotificationAttachment? {
        let size = CGSize(width: 320, height: 320)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors as CFArray, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(
                    gradient, start: .zero,
                    end: CGPoint(x: size.width, y: size.height), options: [])
            }
        }
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".png")
        do {
            try data.write(to: url)
            return try UNNotificationAttachment(identifier: "preview", url: url)
        } catch {
            return nil
        }
    }

    // MARK: - Row helpers

    private func levelRow(icon: String, tint: Color, name: String,
                          detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func legendRow(color: Color, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stackCard(scale: CGFloat, offset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .frame(height: 74)
            .scaleEffect(x: scale)
            .offset(y: offset)
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Mock banner

private struct MockBanner: View {
    let title: String
    var subtitle: String? = nil
    let message: String
    var showThumbnail: Bool
    var labels: Bool
    var squaredBottom = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 9)
                .fill(LinearGradient(colors: [.blue, .indigo],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "paintbrush")
                        .font(.body)
                        .foregroundStyle(.white)
                }
                .anatomyBox(.red, on: labels)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .anatomyBox(.blue, on: labels)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote.weight(.medium))
                        .lineLimit(1)
                        .anatomyBox(.purple, on: labels)
                }
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .anatomyBox(.green, on: labels)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 6) {
                Text("now")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .anatomyBox(.orange, on: labels)
                if showThumbnail {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [.blue, .purple],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                }
            }
        }
        .padding(12)
        .background(
            .regularMaterial,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: squaredBottom ? 0 : 20,
                bottomTrailingRadius: squaredBottom ? 0 : 20, topTrailingRadius: 20)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

private extension View {
    @ViewBuilder
    func anatomyBox(_ color: Color, on: Bool) -> some View {
        if on {
            self
                .padding(2)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: 1))
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack { NotificationAnatomyView() }
}
