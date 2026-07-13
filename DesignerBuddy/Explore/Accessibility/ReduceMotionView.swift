import SwiftUI

struct ReduceMotionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var overrideReduceMotion = false
    @State private var mode: DemoMode = .oneShot
    @State private var showAlt = false
    @State private var animating = false

    private enum DemoMode: String, CaseIterable {
        case oneShot = "One-shot"
        case looping = "Looping"
    }

    private var effectiveReduceMotion: Bool {
        overrideReduceMotion || reduceMotion
    }

    var body: some View {
        List {
            Section("Controls") {
                Picker("Mode", selection: $mode) {
                    ForEach(DemoMode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Toggle("Simulate Reduce Motion for this demo", isOn: $overrideReduceMotion)
                Text(canvasCaption)
                    .font(.mono(.caption))
                    .foregroundStyle(.secondary)
            }

            Section("System Setting") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reduce Motion is:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(reduceMotion ? "On" : "Off")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(reduceMotion ? .orange : .green)
                    }
                    Spacer()
                    Image(systemName: reduceMotion ? "checkmark.shield.fill" : "xmark.shield")
                        .font(.title)
                        .foregroundStyle(reduceMotion ? .orange : .secondary)
                }
                Text("Enable via Settings → Accessibility → Motion → Reduce Motion. Read with @Environment(\\.accessibilityReduceMotion).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Guidance") {
                Text("When reduce motion is on, swap spring/slide animations for a simple .opacity or .easeInOut transition. The content still changes — just without spatial movement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Replace looping or auto-playing animations with a static placeholder when reduce motion is on, so the same information is conveyed without continuous movement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .pinnedPreview {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 190)

                if mode == .oneShot {
                    oneShotTile
                } else {
                    loopingTile
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    trigger()
                } label: {
                    Label(triggerTitle, systemImage: triggerIcon)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(10)
            }
        }
        .navigationTitle("Reduce Motion")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Canvas tiles

    private var oneShotTile: some View {
        ZStack {
            if showAlt {
                demoCircle(color: .purple, label: "B")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(oneShotTransition)
            } else {
                demoCircle(color: .blue, label: "A")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(oneShotTransition)
            }
        }
        .padding(.horizontal, 48)
    }

    private var loopingTile: some View {
        Group {
            if effectiveReduceMotion {
                // Static placeholder instead of animation
                Circle()
                    .fill(Color.orange.opacity(0.4))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("Paused")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    )
            } else if animating {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 56, height: 56)
                    .modifier(PulsingModifier())
            } else {
                Circle()
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: 56, height: 56)
            }
        }
    }

    private var oneShotTransition: AnyTransition {
        effectiveReduceMotion
            ? .opacity
            : .asymmetric(insertion: .slide, removal: .scale.combined(with: .opacity))
    }

    private func demoCircle(color: Color, label: String) -> some View {
        Circle()
            .fill(color.gradient)
            .frame(width: 72, height: 72)
            .overlay(
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            )
    }

    private func trigger() {
        if mode == .oneShot {
            let animation: Animation = effectiveReduceMotion
                ? .easeInOut(duration: 0.2)
                : .spring(duration: 0.45, bounce: 0.3)
            withAnimation(animation) {
                showAlt.toggle()
            }
        } else {
            animating.toggle()
        }
    }

    private var triggerTitle: String {
        mode == .oneShot ? "Toggle" : (animating ? "Stop" : "Play")
    }

    private var triggerIcon: String {
        mode == .oneShot ? "arrow.2.squarepath" : (animating ? "stop.fill" : "play.fill")
    }

    private var canvasCaption: String {
        switch mode {
        case .oneShot:
            return effectiveReduceMotion
                ? "transition: .opacity (cross-fade)"
                : "transition: slide + scale (spring)"
        case .looping:
            if effectiveReduceMotion { return "loop replaced with static placeholder" }
            return animating ? "animation: .easeInOut.repeatForever" : "loop stopped"
        }
    }
}

// MARK: - Pulsing animation modifier

private struct PulsingModifier: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsing ? 1.3 : 1.0)
            .opacity(pulsing ? 0.7 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

#Preview {
    NavigationStack { ReduceMotionView() }
}
