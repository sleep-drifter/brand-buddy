import SwiftUI

struct ContentTransitionView: View {
    @State private var score = 0
    @State private var wordIndex = 0
    @State private var comparisonIndex = 0

    private let words = ["Swift", "Glyph", "Motion", "Fluid", "Morph", "Pixel"]
    private let comparisons = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - numericText
                demoCard(
                    title: ".numericText()",
                    icon: "number.square",
                    color: .blue,
                    code: "Text(\"\\(score)\").contentTransition(.numericText())"
                ) {
                    HStack(spacing: 20) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { score -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }

                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: score < 0))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: score)
                            .frame(minWidth: 80)

                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { score += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // MARK: - interpolate (strings)
                demoCard(
                    title: ".interpolate (strings)",
                    icon: "character.cursor.ibeam",
                    color: .purple,
                    code: "Text(word).contentTransition(.interpolate)"
                ) {
                    VStack(spacing: 12) {
                        Text(words[wordIndex])
                            .font(.system(size: 36, weight: .semibold))
                            .contentTransition(.interpolate)
                            .animation(.easeInOut(duration: 0.4), value: wordIndex)

                        Button("Next word") {
                            withAnimation {
                                wordIndex = (wordIndex + 1) % words.count
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.purple)
                    }
                }

                // MARK: - Comparison
                demoCard(
                    title: "Comparison",
                    icon: "equal.square",
                    color: .orange,
                    code: ".contentTransition(.identity / .opacity / .interpolate)"
                ) {
                    VStack(spacing: 10) {
                        HStack {
                            comparisonLabel("none",        transition: .identity,    color: .gray)
                            comparisonLabel(".opacity",    transition: .opacity,     color: .orange)
                            comparisonLabel(".interpolate", transition: .interpolate, color: .green)
                        }
                        Button("Change") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                comparisonIndex = (comparisonIndex + 1) % comparisons.count
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.orange)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Content Transition")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func comparisonLabel(_ label: String, transition: ContentTransition, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(comparisons[comparisonIndex])
                .font(.system(size: 22, weight: .semibold))
                .contentTransition(transition)
                .frame(width: 90)
            Text(label)
                .font(.caption2.monospaced())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func demoCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        code: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.07))
                    .frame(minHeight: 90)
                content()
                    .padding(.vertical, 12)
            }
            Text(code)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { ContentTransitionView() }
}
