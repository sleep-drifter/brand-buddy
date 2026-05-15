import SwiftUI

struct SymbolEffectsView: View {
    @State private var bounceTrigger = 0
    @State private var pulseTrigger = 0
    @State private var rotateTrigger = 0
    @State private var variableValue: Double = 0.5
    @State private var breatheActive = false
    @State private var appearActive = false

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
