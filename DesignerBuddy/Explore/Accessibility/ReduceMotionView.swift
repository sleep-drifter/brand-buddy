import SwiftUI

struct ReduceMotionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var overrideReduceMotion = false
    @State private var animating = false
    @State private var crossfadeTrigger = false
    @State private var showAlt = false

    private var effectiveReduceMotion: Bool {
        overrideReduceMotion || reduceMotion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - System status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("System Setting", systemImage: "hand.raised")
                            .font(.headline)
                        Spacer()
                    }
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
                    Toggle("Simulate Reduce Motion for this demo", isOn: $overrideReduceMotion)
                        .font(.subheadline)
                    Text("Enable via Settings → Accessibility → Motion → Reduce Motion. Read with @Environment(\\.accessibilityReduceMotion).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Swap animation for cross-fade
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Animation → Cross-Fade Swap", systemImage: "arrow.2.squarepath")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.08))
                            .frame(height: 140)

                        if showAlt {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.purple.gradient)
                                .frame(width: 90, height: 80)
                                .overlay(
                                    Text("State B")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                )
                                .transition(
                                    effectiveReduceMotion
                                        ? .opacity
                                        : .asymmetric(insertion: .slide, removal: .scale.combined(with: .opacity))
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue.gradient)
                                .frame(width: 90, height: 80)
                                .overlay(
                                    Text("State A")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                )
                                .transition(
                                    effectiveReduceMotion
                                        ? .opacity
                                        : .asymmetric(insertion: .slide, removal: .scale.combined(with: .opacity))
                                )
                        }
                    }

                    HStack(spacing: 12) {
                        Button("Toggle") {
                            let animation: Animation = effectiveReduceMotion
                                ? .easeInOut(duration: 0.2)
                                : .spring(duration: 0.45, bounce: 0.3)
                            withAnimation(animation) {
                                showAlt.toggle()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Text(effectiveReduceMotion ? "Using cross-fade (no sliding)" : "Using slide + scale")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("When reduce motion is on, swap spring/slide animations for a simple .opacity or .easeInOut transition. The content still changes — just without spatial movement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Looping animation respect
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Looping Animations", systemImage: "repeat")
                            .font(.headline)
                        Spacer()
                        Button(animating ? "Stop" : "Start") {
                            animating.toggle()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                            .frame(height: 100)

                        if effectiveReduceMotion {
                            // Static placeholder instead of animation
                            Circle()
                                .fill(Color.orange.opacity(0.4))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text("Paused")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                )
                        } else if animating {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 48, height: 48)
                                .modifier(PulsingModifier())
                        } else {
                            Circle()
                                .fill(Color.orange.opacity(0.5))
                                .frame(width: 48, height: 48)
                        }
                    }

                    Text(effectiveReduceMotion
                         ? "Reduce Motion is on — looping animation replaced with a static placeholder."
                         : "Looping animation plays normally. Press Stop to halt it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Reduce Motion")
        .navigationBarTitleDisplayMode(.inline)
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
