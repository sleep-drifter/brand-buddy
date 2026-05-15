import SwiftUI

struct SymbolEffectsView: View {
    @State private var bounceTrigger = 0
    @State private var pulseTrigger = 0
    @State private var rotateTrigger = 0
    @State private var variableValue: Double = 0.5
    @State private var breatheActive = false
    @State private var appearActive = false
    @State private var wiggleTrigger = 0
    @State private var bounceDownTrigger = 0
    @State private var pulseActive = false
    @State private var variableColorActive = false
    @State private var showPlay = true
    @State private var appearByLayerActive = false
    @State private var disappearByLayerActive = false
    @State private var wiggleByLayerTrigger = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Bounce
                effectCard(title: ".bounce", icon: "sparkle", color: .yellow, code: ".symbolEffect(.bounce, value: trigger)") {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.yellow)
                            .symbolEffect(.bounce, value: bounceTrigger)
                        Button("Bounce") { bounceTrigger += 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }

                // MARK: - Pulse
                effectCard(title: ".pulse", icon: "dot.radiowaves.left.and.right", color: .pink, code: ".symbolEffect(.pulse, value: trigger)") {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.pink)
                            .symbolEffect(.pulse, value: pulseTrigger)
                        Button("Pulse") { pulseTrigger += 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }

                // MARK: - Variable Color
                effectCard(title: ".variableColor", icon: "chart.bar.fill", color: .blue, code: ".symbolEffect(.variableColor)") {
                    VStack(spacing: 12) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                            .symbolEffect(.variableColor)
                        Text("Loops automatically")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Breathe (iOS 18+)
                effectCard(title: ".breathe", icon: "lungs.fill", color: .teal, code: ".symbolEffect(.breathe, isActive: isActive)") {
                    VStack(spacing: 12) {
                        Image(systemName: "lungs.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.teal)
                            .symbolEffect(.breathe, isActive: breatheActive)
                        Toggle("Active", isOn: $breatheActive)
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }

                // MARK: - Rotate
                effectCard(title: ".rotate", icon: "gear", color: .gray, code: ".symbolEffect(.rotate, value: trigger)") {
                    VStack(spacing: 12) {
                        Image(systemName: "gear")
                            .font(.system(size: 44))
                            .foregroundStyle(.gray)
                            .symbolEffect(.rotate, value: rotateTrigger)
                        Button("Rotate") { rotateTrigger += 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }

                // MARK: - Appear
                effectCard(title: ".appear / .disappear", icon: "eye", color: .indigo, code: ".symbolEffect(.appear, isActive: isActive)") {
                    VStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.indigo)
                            .symbolEffect(.appear, isActive: appearActive)
                        Toggle("Appear", isOn: $appearActive)
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }

                // MARK: - Wiggle
                effectCard(title: ".wiggle", icon: "bell.badge.fill", color: .orange, code: ".symbolEffect(.wiggle, value: trigger)") {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)
                            .symbolEffect(.wiggle, value: wiggleTrigger)
                        Button("Wiggle") { wiggleTrigger += 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }

                // MARK: - Bounce (arrow)
                effectCard(title: ".bounce (arrow)", icon: "arrow.down.circle", color: .cyan, code: ".symbolEffect(.bounce, value: trigger)") {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.cyan)
                            .symbolEffect(.bounce, value: bounceDownTrigger)
                        Button("Bounce") { bounceDownTrigger += 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }

                // MARK: - Pulse (continuous)
                effectCard(title: ".pulse (continuous)", icon: "heart.fill", color: .red, code: ".symbolEffect(.pulse, isActive: isActive)") {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse, isActive: pulseActive)
                        Toggle("Active", isOn: $pulseActive)
                            .toggleStyle(.button)
                            .controlSize(.small)
                        Text("Continuous pulse, distinct from .breathe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Variable Color Iterative Reversing
                effectCard(title: ".variableColor.iterative.reversing", icon: "wifi", color: .blue, code: ".symbolEffect(.variableColor.iterative.reversing, isActive: isActive)") {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                            .symbolEffect(.variableColor.iterative.reversing, isActive: variableColorActive)
                        Toggle("Active", isOn: $variableColorActive)
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }

                // MARK: - Replace (play/pause toggle)
                effectCard(title: ".replace", icon: "play.fill", color: .green, code: ".contentTransition(.symbolEffect(.replace))") {
                    VStack(spacing: 12) {
                        Button { showPlay.toggle() } label: {
                            Image(systemName: showPlay ? "play.fill" : "pause.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.green)
                                .contentTransition(.symbolEffect(.replace))
                                .animation(.default, value: showPlay)
                        }
                        .buttonStyle(.plain)
                        Text("Most common real-world use — toggle play/pause state")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - By Layer Section Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("By Layer")
                        .font(.title3.weight(.semibold))
                    Text(".byLayer applies the effect to each symbol path layer independently, creating a staggered sequential animation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Appear By Layer
                effectCard(title: ".appear.byLayer", icon: "eye", color: .indigo, code: ".symbolEffect(.appear.byLayer, isActive: isActive)") {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.indigo)
                            .symbolEffect(.appear.byLayer, isActive: appearByLayerActive)
                        Toggle("Appear", isOn: $appearByLayerActive)
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }

                // MARK: - Disappear By Layer
                effectCard(title: ".disappear.byLayer", icon: "eye.slash", color: .purple, code: ".symbolEffect(.disappear.byLayer, isActive: isActive)") {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.down.right.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.purple)
                            .symbolEffect(.disappear.byLayer, isActive: disappearByLayerActive)
                        Toggle("Disappear", isOn: $disappearByLayerActive)
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }

                // MARK: - Wiggle By Layer
                effectCard(title: ".wiggle.byLayer", icon: "waveform", color: .mint, code: ".symbolEffect(.wiggle.byLayer, value: trigger)") {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 44))
                            .foregroundStyle(.mint)
                            .symbolEffect(.wiggle.byLayer, value: wiggleByLayerTrigger)
                        Button("Wiggle Layers") { wiggleByLayerTrigger += 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Symbol Effects")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func effectCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        code: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
            }
            HStack {
                Spacer()
                content()
                Spacer()
            }
            .padding(.vertical, 8)
            Text(code)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { SymbolEffectsView() }
}
