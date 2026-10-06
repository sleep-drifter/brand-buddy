import SwiftUI

// RTL & Localization — what happens to a layout when the language flips or
// grows: mirroring under right-to-left, leading/trailing discipline,
// directional symbols, text-length stress, and locale-aware formatting.

struct RTLLocalizationView: View {

    @State private var rtl = false

    private enum Language: String, CaseIterable {
        case english = "English", german = "German", arabic = "Arabic"
        var locale: Locale {
            switch self {
            case .english: return Locale(identifier: "en_US")
            case .german:  return Locale(identifier: "de_DE")
            case .arabic:  return Locale(identifier: "ar_SA")
            }
        }
    }
    @State private var stressLanguage: Language = .english
    @State private var formatLanguage: Language = .english

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("Localization is a layout problem before it's a translation problem: right-to-left scripts mirror the interface, and German-length strings are ~30% wider than English. Both are testable today, with zero translations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Mirroring ──────────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Layout Mirroring", tag: "layoutDirection")) {
                VStack(spacing: 10) {
                    mockSettingsRow
                    mockMediaRow
                }
                .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
                .padding(.vertical, 4)

                Toggle("Right-to-left", isOn: $rtl.animation(.snappy))
                RefCaption(".environment(\\.layoutDirection, .rightToLeft)")
                HIGNoteRow("Under RTL the whole reading order flips: avatars move to the right, chevrons point left, progress fills right-to-left. Built with HStack and leading/trailing, all of it is free.")
            }

            // ── Leading vs left ────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Leading vs. Left", tag: "Discipline")) {
                VStack(spacing: 10) {
                    labeledDemo("Mirrors — leading alignment") {
                        comparisonRow
                    }
                    labeledDemo("Pinned — opts out of mirroring") {
                        comparisonRow
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.vertical, 4)

                RefCaption("both rows shown in an RTL context; the second pins .leftToRight")
                HIGNoteRow("Think in **leading/trailing**, never left/right — the system does the flipping. Pin a direction only for things that genuinely don't mirror: phone numbers, code, playback timelines, maps.")
            }

            // ── Directional symbols ────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Directional Symbols", tag: "SF Symbols")) {
                symbolRow(name: "chevron.forward", flips: true)
                symbolRow(name: "chevron.right", flips: false)
                symbolRow(name: "arrow.forward", flips: true)
                symbolRow(name: "arrow.right", flips: false)
                HIGNoteRow("**forward/backward** variants mirror with the layout; **right/left** stay fixed. Navigation wants forward; a compass arrow or a redo glyph wants right.")
            }

            // ── Text-length stress ─────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Text-Length Stress", tag: "Pseudo-loc")) {
                Picker("Language", selection: $stressLanguage) {
                    ForEach(Language.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 10) {
                    stressButton
                    stressNavBar
                }
                .environment(\.layoutDirection,
                             stressLanguage == .arabic ? .rightToLeft : .leftToRight)
                .padding(.vertical, 4)

                RefCaption("fixed-width chrome meets German — watch for truncation")
                HIGNoteRow("Leave 30–40% headroom in buttons, tab labels, and nav titles. When a label must truncate, make sure the *start* of the string carries the meaning.")
            }

            // ── Locale formatting ──────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Locale Formatting", tag: "Formatters")) {
                Picker("Locale", selection: $formatLanguage) {
                    ForEach(Language.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)

                Group {
                    LabeledContent("Date") {
                        Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    }
                    LabeledContent("Number") {
                        Text(1234567.89, format: .number)
                    }
                    LabeledContent("Currency") {
                        Text(49.99, format: .currency(code: "USD"))
                    }
                    LabeledContent("Percent") {
                        Text(0.725, format: .percent)
                    }
                }
                .environment(\.locale, formatLanguage.locale)

                RefCaption("Text(value, format:) renders with the environment locale")
                HIGNoteRow("Never assemble dates or numbers from string parts — separators, digit systems, and word order all change by locale. Formatters are the only safe path.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                DoDontRow(good: true,  text: "Test RTL early with the scheme option **App Language → Right-to-Left Pseudolanguage** — no Arabic translation needed.")
                DoDontRow(good: true,  text: "Use `Label` for icon+text pairs: spacing, order, and alignment all localize correctly for free.")
                DoDontRow(good: false, text: "Don't bake text into images or hard-code widths sized to the English string.")
                DoDontRow(good: false, text: "Don't mirror everything blindly — clock faces, music notes, phone numbers, and logos stay put.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                CodeBlockRow(code: """
                    // Preview any view in RTL:
                    MyRow()
                        .environment(\\.layoutDirection, .rightToLeft)

                    // Opt a genuinely directional element out:
                    PlaybackTimeline()
                        .environment(\\.layoutDirection, .leftToRight)

                    // Locale-aware output:
                    Text(price, format: .currency(code: "USD"))
                    Text(date, format: .dateTime.day().month(.wide))
                    """)
            }
        }
        .navigationTitle("RTL & Localization")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Mock rows

    private var mockSettingsRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 7)
                .fill(.blue.gradient)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "globe")
                        .font(.footnote)
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 1) {
                Text("Language & Region")
                    .font(.subheadline)
                Text("English (US)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
    }

    private var mockMediaRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.purple.gradient)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Episode 42 — Layout systems")
                        .font(.subheadline)
                        .lineLimit(1)
                    Text("24 min left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .foregroundStyle(.purple)
            }
            ProgressView(value: 0.62)
                .tint(.purple)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
    }

    private var comparisonRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.alignleft")
                .foregroundStyle(.teal)
            Text("Reading order starts here")
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
    }

    private func labeledDemo<Content: View>(_ label: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .environment(\.layoutDirection, .leftToRight)
            content()
        }
    }

    private func symbolRow(name: String, flips: Bool) -> some View {
        HStack {
            Text(name)
                .font(.mono(.caption))
            Spacer()
            HStack(spacing: 18) {
                VStack(spacing: 3) {
                    Image(systemName: name)
                    Text("LTR").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(spacing: 3) {
                    Image(systemName: name)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text("RTL").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(flips ? .blue : .orange)
        }
    }

    // MARK: - Stress demos

    private var stressStrings: (short: String, long: String, title: String) {
        switch stressLanguage {
        case .english: return ("Continue", "Notification preferences", "Settings")
        case .german:  return ("Fortfahren", "Benachrichtigungseinstellungen", "Einstellungen")
        case .arabic:  return ("متابعة", "تفضيلات الإشعارات", "الإعدادات")
        }
    }

    private var stressButton: some View {
        HStack(spacing: 12) {
            Text(stressStrings.short)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(width: 110, height: 40)
                .background(.blue, in: Capsule())
            Text(stressStrings.long)
                .font(.subheadline)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
                .padding(.vertical, 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.secondary.opacity(0.3),
                                      style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            Spacer()
        }
    }

    private var stressNavBar: some View {
        HStack {
            Image(systemName: "chevron.backward")
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
            Spacer()
            Text(stressStrings.title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { RTLLocalizationView() }
}
