import SwiftUI

struct KeyframeAnimationsView: View {
    @State private var trigger = false

    // Global settings
    @State private var totalDuration: Double = 1.5
    @State private var autoreverses: Bool = false
    @State private var repeatCount: Int = 1

    // Keyframe list
    @State private var keyframes: [CustomKeyframe] = []
    @State private var selectedID: UUID? = nil

    // Add form
    @State private var newProperty: AnimatableProperty = .scale
    @State private var newValue: Double = 1.0
    @State private var newDuration: Double = 0.4
    @State private var newType: KeyframeType = .spring

    // Animation trigger
    @State private var triggerAnimation: Int = 0

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 240)

                        if keyframes.isEmpty {
                            Text("Add keyframes below or start from a preset.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            KeyframeAnimator(
                                initialValue: CustomAnimValues(),
                                trigger: triggerAnimation
                            ) { values in
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "wand.and.sparkles")
                                            .font(.largeTitle)
                                            .foregroundStyle(.white)
                                    )
                                    .scaleEffect(values.scale)
                                    .opacity(values.opacity)
                                    .offset(x: values.offsetX, y: values.offsetY)
                                    .rotationEffect(.degrees(values.rotation))
                            } keyframes: { _ in
                                KeyframeTrack(\.scale) {
                                    for kf in kfsFor(.scale) {
                                        SpringKeyframe(CGFloat(kf.value), duration: kf.duration, spring: springFor(kf.type))
                                    }
                                }
                                KeyframeTrack(\.offsetX) {
                                    for kf in kfsFor(.offsetX) {
                                        SpringKeyframe(CGFloat(kf.value), duration: kf.duration, spring: springFor(kf.type))
                                    }
                                }
                                KeyframeTrack(\.offsetY) {
                                    for kf in kfsFor(.offsetY) {
                                        SpringKeyframe(CGFloat(kf.value), duration: kf.duration, spring: springFor(kf.type))
                                    }
                                }
                                KeyframeTrack(\.opacity) {
                                    for kf in kfsFor(.opacity) {
                                        SpringKeyframe(kf.value, duration: kf.duration, spring: springFor(kf.type))
                                    }
                                }
                                KeyframeTrack(\.rotation) {
                                    for kf in kfsFor(.rotation) {
                                        SpringKeyframe(kf.value, duration: kf.duration, spring: springFor(kf.type))
                                    }
                                }
                            }
                        }
                    }

                    Button("▶ Trigger Animation") {
                        triggerAnimation += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(keyframes.isEmpty)

                    Text("Each KeyframeTrack targets one property. Values animate sequentially through the list in order.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Global Settings") {
                LabeledContent("Total duration: \(totalDuration, specifier: "%.1f")s") {
                    Slider(value: $totalDuration, in: 0.5...4.0, step: 0.1)
                }
                Toggle("Auto-reverses", isOn: $autoreverses)
                Stepper("Repeat: \(repeatCount == 0 ? "∞" : "\(repeatCount)×")", value: $repeatCount, in: 0...10)
            }

            Section("Keyframes") {
                if keyframes.isEmpty {
                    Text("No keyframes yet — add one below.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(keyframes) { kf in
                        keyframeRow(kf)
                    }
                }
            }

            Section("Add Keyframe") {
                Picker("Property", selection: $newProperty) {
                    ForEach(AnimatableProperty.allCases) { p in
                        Text(p.rawValue.capitalized).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: newProperty) { _, p in
                    newValue = p.defaultValue
                }

                LabeledContent("Value: \(valueLabel(for: newProperty, value: newValue))") {
                    Slider(value: $newValue, in: newProperty.range)
                }

                LabeledContent("Duration: \(newDuration, specifier: "%.2f")s") {
                    Slider(value: $newDuration, in: 0.1...1.5, step: 0.05)
                }

                Picker("Type", selection: $newType) {
                    ForEach(KeyframeType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                Button("+ Add Keyframe") {
                    keyframes.append(CustomKeyframe(
                        property: newProperty,
                        value: newValue,
                        duration: newDuration,
                        type: newType
                    ))
                }
                .frame(maxWidth: .infinity)
            }

            Section("Presets") {
                presetRow(name: "Bounce", detail: "Scale pop with a vertical hop", count: 6, preset: .bounce)
                presetRow(name: "Fade In", detail: "Opacity and scale entrance", count: 4, preset: .fadeIn)
                presetRow(name: "Swing", detail: "Rotation oscillation that settles to rest", count: 5, preset: .swing)
            }

            Section("KeyframeAnimator") {
                VStack(alignment: .leading, spacing: 12) {
                    KeyframeAnimator(
                        initialValue: CardAnimationValues(),
                        trigger: trigger
                    ) { values in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.indigo.opacity(0.1))
                                .frame(height: 180)
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.indigo.gradient)
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Image(systemName: "wand.and.sparkles")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                )
                                .scaleEffect(values.scale)
                                .opacity(values.opacity)
                                .offset(y: values.verticalOffset)
                        }
                    } keyframes: { _ in
                        KeyframeTrack(\.verticalOffset) {
                            LinearKeyframe(0, duration: 0.1)
                            SpringKeyframe(-60, duration: 0.35, spring: .bouncy)
                            SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                        }
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(1.0, duration: 0.1)
                            SpringKeyframe(1.3, duration: 0.2, spring: .snappy)
                            SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(1.0, duration: 0.1)
                            LinearKeyframe(0.6, duration: 0.2)
                            LinearKeyframe(1.0, duration: 0.3)
                        }
                    }

                    Button("Trigger Animation") {
                        trigger.toggle()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Text("KeyframeAnimator drives multiple properties along independent timelines simultaneously. Each KeyframeTrack targets one property via a key path.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Keyframe Types") {
                keyframeTypeRow(
                    name: "LinearKeyframe",
                    desc: "Constant easing. Good for opacity or color."
                )
                keyframeTypeRow(
                    name: "SpringKeyframe",
                    desc: "Physics spring curve. Great for scale and position."
                )
                keyframeTypeRow(
                    name: "CubicKeyframe",
                    desc: "Cubic Bézier easing. Precise control over acceleration."
                )
                keyframeTypeRow(
                    name: "MoveKeyframe",
                    desc: "Instant jump to a value with no interpolation."
                )
            }
        }
        .navigationTitle("Keyframe Animations")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Keyframe Row

    @ViewBuilder
    private func keyframeRow(_ kf: CustomKeyframe) -> some View {
        let isSelected = selectedID == kf.id
        HStack(spacing: 10) {
            Text(kf.property.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(kf.property.color.opacity(0.15), in: Capsule())
                .foregroundStyle(kf.property.color)
            Text(valueLabel(for: kf.property, value: kf.value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
            Spacer()
            Text("\(kf.duration, specifier: "%.2f")s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(kf.type.rawValue)
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 4))
        }
        .contentShape(Rectangle())
        .onTapGesture { selectedID = isSelected ? nil : kf.id }
        .overlay(alignment: .trailing) {
            if isSelected {
                Button("Remove") {
                    keyframes.removeAll { $0.id == kf.id }
                    selectedID = nil
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
    }

    // MARK: - Preset Row

    private func presetRow(name: String, detail: String, count: Int, preset: Preset) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.subheadline).foregroundStyle(.primary)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(count) keyframes")
                    .font(.mono(.caption2)).foregroundStyle(.tertiary)
            }
        }
    }

    private func keyframeTypeRow(name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(name)
                .font(.mono(.caption))
                .frame(width: 130, alignment: .leading)
            Text(desc)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func kfsFor(_ property: AnimatableProperty) -> [CustomKeyframe] {
        let filtered = keyframes.filter { $0.property == property }
        guard !filtered.isEmpty else {
            return [CustomKeyframe(property: property, value: property.defaultValue, duration: max(totalDuration, 0.1), type: .linear)]
        }
        return filtered
    }

    private func springFor(_ type: KeyframeType) -> Spring {
        switch type {
        case .linear: return .init(response: 0.2, dampingRatio: 1.0)
        case .spring: return .bouncy
        case .cubic:  return .init(response: 0.5, dampingRatio: 0.85)
        }
    }

    private func valueLabel(for property: AnimatableProperty, value: Double) -> String {
        switch property {
        case .scale:              return String(format: "%.2f×", value)
        case .offsetX, .offsetY: return String(format: "%.0fpt", value)
        case .opacity:            return String(format: "%.2f", value)
        case .rotation:           return String(format: "%.0f°", value)
        }
    }

    private enum Preset { case bounce, fadeIn, swing }

    private func applyPreset(_ preset: Preset) {
        switch preset {
        case .bounce:
            keyframes = [
                CustomKeyframe(property: .scale,   value: 1.0,  duration: 0.1, type: .linear),
                CustomKeyframe(property: .scale,   value: 1.4,  duration: 0.25, type: .spring),
                CustomKeyframe(property: .scale,   value: 1.0,  duration: 0.35, type: .spring),
                CustomKeyframe(property: .offsetY, value: 0,    duration: 0.1,  type: .linear),
                CustomKeyframe(property: .offsetY, value: -60,  duration: 0.25, type: .spring),
                CustomKeyframe(property: .offsetY, value: 0,    duration: 0.35, type: .spring),
            ]
        case .fadeIn:
            keyframes = [
                CustomKeyframe(property: .opacity, value: 0.0, duration: 0.05, type: .linear),
                CustomKeyframe(property: .opacity, value: 1.0, duration: 0.5,  type: .cubic),
                CustomKeyframe(property: .scale,   value: 0.8, duration: 0.05, type: .linear),
                CustomKeyframe(property: .scale,   value: 1.0, duration: 0.5,  type: .spring),
            ]
        case .swing:
            keyframes = [
                CustomKeyframe(property: .rotation, value: 0,    duration: 0.05, type: .linear),
                CustomKeyframe(property: .rotation, value: -25,  duration: 0.2,  type: .spring),
                CustomKeyframe(property: .rotation, value: 25,   duration: 0.2,  type: .spring),
                CustomKeyframe(property: .rotation, value: -15,  duration: 0.15, type: .spring),
                CustomKeyframe(property: .rotation, value: 0,    duration: 0.15, type: .spring),
            ]
        }
    }
}

// MARK: - Animation Values

private struct CardAnimationValues {
    var verticalOffset: CGFloat = 0
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
}

// MARK: - Custom Keyframe Builder Types

private enum AnimatableProperty: String, CaseIterable, Identifiable {
    case scale, offsetX, offsetY, opacity, rotation
    var id: String { rawValue }

    var range: ClosedRange<Double> {
        switch self {
        case .scale:              return 0.1...3.0
        case .offsetX, .offsetY: return -150...150
        case .opacity:            return 0...1
        case .rotation:           return -360...360
        }
    }

    var defaultValue: Double {
        switch self {
        case .scale:   return 1.0
        case .opacity: return 1.0
        default:       return 0.0
        }
    }

    var color: Color {
        switch self {
        case .scale:    return .indigo
        case .offsetX:  return .orange
        case .offsetY:  return .teal
        case .opacity:  return .pink
        case .rotation: return .purple
        }
    }
}

private enum KeyframeType: String, CaseIterable {
    case linear = "Linear"
    case spring = "Spring"
    case cubic  = "Cubic"
}

private struct CustomKeyframe: Identifiable {
    let id = UUID()
    var property: AnimatableProperty
    var value: Double
    var duration: Double
    var type: KeyframeType
}

// MARK: - Custom Keyframe Values (for KeyframeAnimator)

private struct CustomAnimValues {
    var scale: CGFloat     = 1.0
    var offsetX: CGFloat   = 0
    var offsetY: CGFloat   = 0
    var opacity: Double    = 1.0
    var rotation: Double   = 0
}

#Preview {
    NavigationStack { KeyframeAnimationsView() }
}
