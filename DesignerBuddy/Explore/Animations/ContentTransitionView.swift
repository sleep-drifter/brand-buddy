import SwiftUI

struct ContentTransitionView: View {
    @State private var value = 2048
    @State private var wordDone = false
    @State private var style: MorphStyle = .numericText
    @State private var duration: Double = 0.4

    var body: some View {
        List {
            Section("Controls") {
                HStack(spacing: 12) {
                    Button("−1") { value = max(value - 1, 0) }
                    Button("+1") { value = min(value + 1, 9999) }
                    Button("Random") { value = Int.random(in: 1000...9999) }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                LabeledContent("duration: \(duration, specifier: "%.2f")s") {
                    Slider(value: $duration, in: 0.1...1.5)
                }
            }

            Section("Transition Types") {
                PresetChipRow(
                    chips: MorphStyle.allCases.map { s in
                        PresetChip(name: s.rawValue, detail: s.detail)
                    },
                    selectedID: styleSelection
                ) { _ in
                    value = Int.random(in: 1000...9999)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .pinnedPreview(entry: "Content Transition", shuffle: { value = Int.random(in: 1000...9999) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.quaternary)
                    .frame(height: 160)

                VStack(spacing: 12) {
                    Text("\(value)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(style.transition)
                        .animation(.easeInOut(duration: duration), value: value)

                    VStack(spacing: 2) {
                        Text(wordDone ? "Done" : "Syncing…")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .contentTransition(style.transition)
                            .animation(.easeInOut(duration: duration), value: wordDone)
                        Text("Tap the word to swap it")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { wordDone.toggle() }
                }
            }
        }
        .navigationTitle("Content Transition")
    }

    private var styleSelection: Binding<String?> {
        Binding(
            get: { style.rawValue },
            set: { name in
                guard let name, let s = MorphStyle(rawValue: name) else { return }
                style = s
            }
        )
    }

}

// MARK: - Morph Styles

private enum MorphStyle: String, CaseIterable {
    case numericText = "Numeric Roll"
    case numericTextDown = "Numeric Roll (down)"
    case interpolate = "Interpolate"
    case opacity = "Cross-fade"
    case identity = "Instant"

    var transition: ContentTransition {
        switch self {
        case .numericText:     return .numericText()
        case .numericTextDown: return .numericText(countsDown: true)
        case .interpolate:     return .interpolate
        case .opacity:         return .opacity
        case .identity:        return .identity
        }
    }

    var detail: String {
        switch self {
        case .numericText:     return "Digits roll vertically like an odometer."
        case .numericTextDown: return "Digits roll the other way for decreasing values."
        case .interpolate:     return "Morphs glyphs, weight, and size between states."
        case .opacity:         return "Cross-fades the old and new content."
        case .identity:        return "Swaps instantly with no animation."
        }
    }
}

#Preview {
    NavigationStack { ContentTransitionView() }
        .environmentObject(PinsStore())
}
