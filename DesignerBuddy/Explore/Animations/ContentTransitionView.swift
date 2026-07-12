import SwiftUI

struct ContentTransitionView: View {
    @State private var value = 2048
    @State private var wordDone = false
    @State private var style: MorphStyle = .numericText
    @State private var duration: Double = 0.4

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 240)

                        VStack(spacing: 20) {
                            Text("\(value)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(style.transition)
                                .animation(.easeInOut(duration: duration), value: value)

                            VStack(spacing: 4) {
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

                    Text(generatedCode)
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                Picker("Transition", selection: $style) {
                    ForEach(MorphStyle.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.menu)

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
                ForEach(MorphStyle.allCases, id: \.self) { s in
                    Button {
                        style = s
                        value = Int.random(in: 1000...9999)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.rawValue).font(.subheadline).foregroundStyle(.primary)
                                Text(s.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(s.code)
                                .font(.mono(.caption2)).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Content Transition")
        .navigationBarTitleDisplayMode(.large)
    }

    private var generatedCode: String {
        let animation = String(format: ".easeInOut(duration: %.2f)", duration)
        return "Text(\"\\(value)\")\n    .contentTransition(\(style.code))\n    .animation(\(animation), value: value)"
    }
}

// MARK: - Morph Styles

private enum MorphStyle: String, CaseIterable {
    case numericText = "numericText"
    case numericTextDown = "numericText (counts down)"
    case interpolate = "interpolate"
    case opacity = "opacity"
    case identity = "identity"

    var transition: ContentTransition {
        switch self {
        case .numericText:     return .numericText()
        case .numericTextDown: return .numericText(countsDown: true)
        case .interpolate:     return .interpolate
        case .opacity:         return .opacity
        case .identity:        return .identity
        }
    }

    var code: String {
        switch self {
        case .numericText:     return ".numericText()"
        case .numericTextDown: return ".numericText(countsDown: true)"
        case .interpolate:     return ".interpolate"
        case .opacity:         return ".opacity"
        case .identity:        return ".identity"
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
}
