import SwiftUI
import CoreHaptics
import Combine
import UIKit

// MARK: - Custom Haptics View

struct CustomHapticsView: View {
    @StateObject private var hapticsEngine = HapticsEngine()
    @State private var mode: HapticMode = .transient

    private enum HapticMode: String, CaseIterable {
        case transient = "Transient"
        case continuous = "Continuous"
    }

    private var currentIntensity: Float {
        mode == .transient ? hapticsEngine.transientIntensity : hapticsEngine.continuousIntensity
    }

    private var currentSharpness: Float {
        mode == .transient ? hapticsEngine.transientSharpness : hapticsEngine.continuousSharpness
    }

    private var envelopeColor: Color {
        Color.blue.mix(with: .orange, by: Double(currentSharpness))
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    #if targetEnvironment(simulator)
                    simulatorBanner
                    #endif

                    VStack(spacing: 10) {
                        envelopePlot
                            .frame(height: 180)

                        HStack(spacing: 8) {
                            Text("dull")
                                .font(.mono(.caption2))
                                .foregroundStyle(.secondary)
                            LinearGradient(colors: [.blue, .orange], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 56, height: 6)
                                .clipShape(Capsule())
                            Text("crisp")
                                .font(.mono(.caption2))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(readout)
                                .font(.mono(.caption2))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    Button {
                        if mode == .transient {
                            hapticsEngine.playTransient()
                        } else {
                            hapticsEngine.playContinuous()
                        }
                    } label: {
                        Label(mode == .transient ? "Play Transient" : "Play Continuous", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                Picker("Mode", selection: $mode) {
                    ForEach(HapticMode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)

                if mode == .transient {
                    LabeledContent("intensity: \(hapticsEngine.transientIntensity, specifier: "%.2f")") {
                        Slider(value: $hapticsEngine.transientIntensity, in: 0...1)
                    }
                    LabeledContent("sharpness: \(hapticsEngine.transientSharpness, specifier: "%.2f")") {
                        Slider(value: $hapticsEngine.transientSharpness, in: 0...1)
                    }
                } else {
                    LabeledContent("intensity: \(hapticsEngine.continuousIntensity, specifier: "%.2f")") {
                        Slider(value: $hapticsEngine.continuousIntensity, in: 0...1)
                    }
                    LabeledContent("sharpness: \(hapticsEngine.continuousSharpness, specifier: "%.2f")") {
                        Slider(value: $hapticsEngine.continuousSharpness, in: 0...1)
                    }
                    LabeledContent("duration: \(hapticsEngine.continuousDuration, specifier: "%.2f")s") {
                        Slider(value: $hapticsEngine.continuousDuration, in: 0.1...2.0)
                    }
                }

                Text(mode == .transient
                     ? "Transients feel like taps. High sharpness = crisp click. Low sharpness = thud."
                     : "Continuous events sustain over time. Useful for loading states, drag feedback, or rumble effects.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Standard Feedback") {
                Text("Impact — UIImpactFeedbackGenerator")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(ImpactItem.all) { item in
                    HapticButton(label: item.name, subtitle: item.description) {
                        let g = UIImpactFeedbackGenerator(style: item.style)
                        g.prepare()
                        g.impactOccurred()
                    }
                }

                Text("Notification — UINotificationFeedbackGenerator")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(NotificationItem.all) { item in
                    HapticButton(label: item.name, subtitle: item.description) {
                        let g = UINotificationFeedbackGenerator()
                        g.prepare()
                        g.notificationOccurred(item.type)
                    }
                }

                Text("Selection — UISelectionFeedbackGenerator")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HapticButton(
                    label: "Selection Changed",
                    subtitle: "Light tick — use when moving through a picker or list selection."
                ) {
                    let g = UISelectionFeedbackGenerator()
                    g.prepare()
                    g.selectionChanged()
                }

                Text("Built-in generators cover most needs. Reach for CoreHaptics (above) only when you need custom intensity, sharpness, or timed patterns.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Named Patterns") {
                ForEach(HapticsEngine.NamedPattern.allCases, id: \.self) { pattern in
                    Button {
                        hapticsEngine.playPattern(pattern)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.title).font(.subheadline).fontWeight(.medium)
                                Text(pattern.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle").foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
                Text("Custom CoreHaptics compositions that approximate the system generators in Standard Feedback — built from the same transient/continuous primitives as the plot above, so you can read the recipes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Usage Guidelines") {
                ForEach(HapticGuideline.all) { guide in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: guide.icon)
                                .foregroundStyle(guide.positive ? .green : .red)
                                .font(.caption)
                                .frame(width: 16)
                            Text(guide.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(guide.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 22)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("API Reference") {
                RefRow(type: "CHHapticEngine", detail: "The engine itself — create once, reuse")
                RefRow(type: "CHHapticEvent", detail: "Transient or continuous, with parameters")
                RefRow(type: "CHHapticPattern", detail: "Sequence of events at relative times")
                RefRow(type: "CHHapticPatternPlayer", detail: "Plays a pattern, can be paused/stopped")
            }
        }
        .navigationTitle("Custom Haptics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { hapticsEngine.start() }
        .onDisappear { hapticsEngine.stop() }
    }

    // MARK: Envelope Plot

    private var envelopePlot: some View {
        Canvas { context, size in
            drawEnvelope(context, size: size)
        }
    }

    private func drawEnvelope(_ context: GraphicsContext, size: CGSize) {
        let labelGutter: CGFloat = 16
        let plot = CGRect(
            x: 8,
            y: 8,
            width: size.width - 16,
            height: size.height - 16 - labelGutter
        )
        let baseline = plot.maxY
        let maxTime: CGFloat = 2.0

        // Intensity gridlines (0, 0.5, 1.0)
        var grid = Path()
        for fraction in [0.0, 0.5, 1.0] {
            let y = baseline - plot.height * CGFloat(fraction)
            grid.move(to: CGPoint(x: plot.minX, y: y))
            grid.addLine(to: CGPoint(x: plot.maxX, y: y))
        }
        context.stroke(grid, with: .color(.gray.opacity(0.18)), lineWidth: 1)
        context.draw(
            Text("1.0").font(.system(size: 9)).foregroundStyle(.secondary),
            at: CGPoint(x: plot.minX + 2, y: plot.minY - 1),
            anchor: .bottomLeading
        )

        // Time ticks every 0.5s, labels at whole seconds
        for tick in [0.0, 0.5, 1.0, 1.5, 2.0] {
            let x = plot.minX + plot.width * CGFloat(tick) / maxTime
            var tickPath = Path()
            tickPath.move(to: CGPoint(x: x, y: baseline))
            tickPath.addLine(to: CGPoint(x: x, y: baseline + 4))
            context.stroke(tickPath, with: .color(.gray.opacity(0.4)), lineWidth: 1)
            if tick == tick.rounded() {
                context.draw(
                    Text("\(Int(tick))s").font(.system(size: 9)).foregroundStyle(.secondary),
                    at: CGPoint(x: x, y: baseline + 6),
                    anchor: .top
                )
            }
        }

        // Envelope: x = time, y = intensity, color = sharpness
        let color = envelopeColor
        switch mode {
        case .transient:
            let peakHeight = plot.height * CGFloat(currentIntensity)
            var spike = Path()
            spike.move(to: CGPoint(x: plot.minX, y: baseline))
            spike.addLine(to: CGPoint(x: plot.minX + 5, y: baseline - peakHeight))
            spike.addLine(to: CGPoint(x: plot.minX + 16, y: baseline))
            spike.closeSubpath()
            context.fill(spike, with: .color(color.opacity(0.7)))
            context.stroke(spike, with: .color(color), lineWidth: 1.5)
        case .continuous:
            let blockWidth = plot.width * CGFloat(hapticsEngine.continuousDuration) / maxTime
            let blockHeight = plot.height * CGFloat(currentIntensity)
            let block = CGRect(x: plot.minX, y: baseline - blockHeight, width: blockWidth, height: blockHeight)
            context.fill(Path(block), with: .color(color.opacity(0.35)))
            var edge = Path()
            edge.move(to: CGPoint(x: block.minX, y: block.minY))
            edge.addLine(to: CGPoint(x: block.maxX, y: block.minY))
            edge.addLine(to: CGPoint(x: block.maxX, y: baseline))
            context.stroke(edge, with: .color(color), lineWidth: 2)
        }
    }

    private var readout: String {
        switch mode {
        case .transient:
            return String(format: "spike @ t=0 · i %.2f", currentIntensity)
        case .continuous:
            return String(format: "%.2fs @ i %.2f", hapticsEngine.continuousDuration, currentIntensity)
        }
    }

    // MARK: Simulator Banner

    private var simulatorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.slash").foregroundStyle(.orange)
            Text("Haptics require a physical device. The UI below shows the API — patterns won't play in Simulator.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Supporting Views

private struct RefRow: View {
    let type: String
    let detail: String
    var body: some View {
        HStack(alignment: .top) {
            Text(type).font(.caption.monospaced()).foregroundStyle(.blue).frame(width: 170, alignment: .leading)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Haptics Engine

@MainActor
class HapticsEngine: ObservableObject {
    private var engine: CHHapticEngine?

    @Published var transientIntensity: Float = 0.8
    @Published var transientSharpness: Float = 0.5
    @Published var continuousIntensity: Float = 0.6
    @Published var continuousSharpness: Float = 0.3
    @Published var continuousDuration: Float = 0.5

    enum NamedPattern: CaseIterable {
        case selection, impact, warning, success

        var title: String {
            switch self {
            case .selection: return "Selection"
            case .impact:    return "Impact"
            case .warning:   return "Warning"
            case .success:   return "Success"
            }
        }
        var description: String {
            switch self {
            case .selection: return "Light tap — for picker scrolls or list selection"
            case .impact:    return "Medium tap — for button presses"
            case .warning:   return "Two sharp taps — for destructive actions"
            case .success:   return "Soft rise + gentle end — for completion"
            }
        }
    }

    func start() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch { }
    }

    func stop() {
        engine?.stop()
    }

    func playTransient() {
        guard let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: transientIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: transientSharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        play(events: [event], in: engine)
    }

    func playContinuous() {
        guard let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: continuousIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: continuousSharpness)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness],
                                  relativeTime: 0, duration: TimeInterval(continuousDuration))
        play(events: [event], in: engine)
    }

    func playPattern(_ pattern: NamedPattern) {
        guard let engine else { return }
        var events: [CHHapticEvent] = []
        switch pattern {
        case .selection:
            events = [makeTransient(t: 0, i: 0.4, s: 0.8)]
        case .impact:
            events = [makeTransient(t: 0, i: 0.8, s: 0.5)]
        case .warning:
            events = [makeTransient(t: 0, i: 0.9, s: 0.9), makeTransient(t: 0.15, i: 0.7, s: 0.9)]
        case .success:
            events = [
                makeContinuous(t: 0, d: 0.1, i: 0.3, s: 0.1),
                makeTransient(t: 0.12, i: 0.5, s: 0.3),
            ]
        }
        play(events: events, in: engine)
    }

    private func makeTransient(t: TimeInterval, i: Float, s: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: i),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: s),
        ], relativeTime: t)
    }

    private func makeContinuous(t: TimeInterval, d: TimeInterval, i: Float, s: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: i),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: s),
        ], relativeTime: t, duration: d)
    }

    private func play(events: [CHHapticEvent], in engine: CHHapticEngine) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }
}

#Preview {
    NavigationStack { CustomHapticsView() }
}
