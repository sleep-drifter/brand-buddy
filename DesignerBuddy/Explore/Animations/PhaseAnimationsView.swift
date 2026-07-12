import SwiftUI

struct PhaseAnimationsView: View {
    @State private var mode: PhaseMode = .loop
    @State private var phaseSet: PhaseSet = .bounce
    @State private var stepStyle: StepStyle = .spring
    @State private var isAnimating = false
    @State private var manualIndex = 0

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 240)

                        switch mode {
                        case .loop:
                            if isAnimating {
                                PhaseAnimator(phaseSet.phases) { phase in
                                    tile(for: phase)
                                } animation: { _ in
                                    stepAnimation
                                }
                            } else {
                                tile(for: phaseSet.phases[0])
                            }
                        case .manual:
                            tile(for: currentManualPhase)
                                .animation(stepAnimation, value: manualIndex)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture { handleCanvasTap() }
                    .overlay(alignment: .bottom) {
                        if mode == .loop && !isAnimating {
                            Text("Tap to start looping")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.bottom, 12)
                        }
                    }

                    switch mode {
                    case .loop:
                        Button(isAnimating ? "Pause" : "Play") {
                            isAnimating.toggle()
                        }
                        .buttonStyle(.bordered)
                    case .manual:
                        HStack(spacing: 8) {
                            ForEach(Array(phaseSet.phases.enumerated()), id: \.offset) { index, phase in
                                Button(phase.label) {
                                    manualIndex = index
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(manualIndex == index ? .accentColor : nil)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                Picker("Mode", selection: $mode) {
                    ForEach(PhaseMode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)

                Picker("Phase set", selection: $phaseSet) {
                    ForEach(PhaseSet.allCases, id: \.self) { set in
                        Text("\(set.rawValue) (\(set.phaseList))")
                    }
                }
                .pickerStyle(.menu)

                Picker("Step animation", selection: $stepStyle) {
                    ForEach(StepStyle.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }

            Section("Notes") {
                Text("PhaseAnimator cycles through an array of values automatically. Each transition uses the animation returned for the incoming phase.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Passing a single-element array to PhaseAnimator lets you drive it manually — useful for triggered one-shot sequences triggered by state.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: phaseSet) { _, _ in
            manualIndex = 0
        }
        .navigationTitle("Phase Animations")
        .navigationBarTitleDisplayMode(.large)
    }

    private var currentManualPhase: DemoPhase {
        let phases = phaseSet.phases
        return phases[min(manualIndex, phases.count - 1)]
    }

    private var stepAnimation: Animation {
        switch stepStyle {
        case .spring:    return .spring(duration: 0.4, bounce: 0.4)
        case .easeInOut: return .easeInOut(duration: 0.4)
        }
    }

    private func handleCanvasTap() {
        switch mode {
        case .loop:
            isAnimating.toggle()
        case .manual:
            manualIndex = (manualIndex + 1) % phaseSet.phases.count
        }
    }

    private func tile(for phase: DemoPhase) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.teal.gradient)
            .frame(width: 72, height: 72)
            .overlay(
                Text(phase.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            )
            .scaleEffect(phase.scale)
            .rotationEffect(.degrees(phase.rotation))
            .offset(x: phase.offsetX, y: phase.offsetY)
            .opacity(phase.opacity)
    }
}

// MARK: - Phase Definitions

private struct DemoPhase: Hashable {
    var label: String
    var scale: CGFloat = 1.0
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var rotation: Double = 0
    var opacity: Double = 1.0
}

private enum PhaseMode: String, CaseIterable {
    case loop = "Loop"
    case manual = "Manual"
}

private enum StepStyle: String, CaseIterable {
    case spring = "Spring"
    case easeInOut = "EaseInOut"
}

private enum PhaseSet: String, CaseIterable {
    case bounce = "Bounce"
    case pulse = "Pulse"
    case shake = "Shake"

    var phases: [DemoPhase] {
        switch self {
        case .bounce:
            return [
                DemoPhase(label: "Rest"),
                DemoPhase(label: "Up", scale: 1.1, offsetY: -60),
                DemoPhase(label: "Down", scale: 0.92, offsetY: 14),
            ]
        case .pulse:
            return [
                DemoPhase(label: "Small", scale: 0.75, opacity: 0.85),
                DemoPhase(label: "Big", scale: 1.3),
            ]
        case .shake:
            return [
                DemoPhase(label: "Left", offsetX: -36, rotation: -8),
                DemoPhase(label: "Right", offsetX: 36, rotation: 8),
                DemoPhase(label: "Center"),
            ]
        }
    }

    var phaseList: String {
        phases.map(\.label).joined(separator: " · ")
    }
}

#Preview {
    NavigationStack { PhaseAnimationsView() }
}
