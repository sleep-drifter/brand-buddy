import SwiftUI

struct PhaseAnimationsView: View {
    @State private var isAnimating = false
    @State private var manualPhase: BouncePhase = .resting

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Looping PhaseAnimator
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("PhaseAnimator — Looping", systemImage: "waveform.path")
                            .font(.headline)
                        Spacer()
                        Button(isAnimating ? "Pause" : "Play") {
                            isAnimating.toggle()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.teal.opacity(0.08))
                            .frame(height: 160)

                        if isAnimating {
                            PhaseAnimator([
                                LoadPhase.idle,
                                LoadPhase.scaleUp,
                                LoadPhase.moveRight,
                                LoadPhase.scaleDown,
                            ]) { phase in
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.teal.gradient)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "arrow.right")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                    )
                                    .scaleEffect(phase.scale)
                                    .offset(x: phase.offsetX)
                                    .opacity(phase.opacity)
                            } animation: { phase in
                                switch phase {
                                case .idle:       .easeIn(duration: 0.3)
                                case .scaleUp:    .spring(duration: 0.3, bounce: 0.4)
                                case .moveRight:  .easeInOut(duration: 0.4)
                                case .scaleDown:  .easeOut(duration: 0.3)
                                }
                            }
                        } else {
                            Text("Tap Play to start looping")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("PhaseAnimator cycles through an array of values automatically. Each transition uses the animation returned for the incoming phase.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Manual phase control
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Manual Phase Control", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        Spacer()
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                            .frame(height: 140)

                        PhaseAnimator([manualPhase]) { phase in
                            Circle()
                                .fill(Color.orange.gradient)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text(phase.label)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white)
                                )
                                .scaleEffect(phase.scale)
                                .opacity(phase.opacity)
                        } animation: { _ in .spring(duration: 0.5, bounce: 0.3) }
                    }

                    HStack(spacing: 8) {
                        ForEach(BouncePhase.allCases, id: \.self) { phase in
                            Button(phase.label) {
                                manualPhase = phase
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(manualPhase == phase ? .orange : nil)
                        }
                    }

                    Text("Passing a single-element array to PhaseAnimator lets you drive it manually — useful for triggered one-shot sequences triggered by state.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Phase Animations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Phase Definitions

private enum LoadPhase: CaseIterable {
    case idle, scaleUp, moveRight, scaleDown

    var scale: CGFloat {
        switch self {
        case .idle:       return 1.0
        case .scaleUp:    return 1.4
        case .moveRight:  return 1.0
        case .scaleDown:  return 0.7
        }
    }

    var offsetX: CGFloat {
        switch self {
        case .idle, .scaleUp, .scaleDown: return 0
        case .moveRight: return 60
        }
    }

    var opacity: Double {
        switch self {
        case .idle, .scaleUp, .moveRight: return 1.0
        case .scaleDown: return 0.6
        }
    }
}

private enum BouncePhase: CaseIterable {
    case resting, bounced, shrunk

    var scale: CGFloat {
        switch self {
        case .resting: return 1.0
        case .bounced: return 1.5
        case .shrunk:  return 0.6
        }
    }

    var opacity: Double {
        switch self {
        case .resting: return 1.0
        case .bounced: return 0.8
        case .shrunk:  return 0.4
        }
    }

    var label: String {
        switch self {
        case .resting: return "Rest"
        case .bounced: return "Big"
        case .shrunk:  return "Small"
        }
    }
}

#Preview {
    NavigationStack { PhaseAnimationsView() }
}
