import SwiftUI

struct TransitionsView: View {
    @State private var isShowing = true
    @State private var transitionKind: TransitionKind = .slide
    @State private var duration: Double = 0.4
    @State private var curve: CurveKind = .easeInOut

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 240)

                        if isShowing {
                            transitionedTile
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture { toggle() }
                    .overlay(alignment: .bottom) {
                        if !isShowing {
                            Text("Tap to show")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.bottom, 12)
                        }
                    }

                    Button(isShowing ? "Hide" : "Show") {
                        toggle()
                    }
                    .buttonStyle(.bordered)

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
                Picker("Transition", selection: $transitionKind) {
                    ForEach(TransitionKind.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.menu)

                LabeledContent("duration: \(duration, specifier: "%.2f")s") {
                    Slider(value: $duration, in: 0.1...1.5)
                }

                Picker("Curve", selection: $curve) {
                    ForEach(CurveKind.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }

            Section("Transition Types") {
                ForEach(TransitionKind.allCases, id: \.self) { kind in
                    Button {
                        transitionKind = kind
                        replay()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.rawValue).font(.subheadline).foregroundStyle(.primary)
                                Text(kind.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(kind.snippet)
                                .font(.mono(.caption2)).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Transitions")
        .navigationBarTitleDisplayMode(.large)
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.tint)
            .frame(width: 96, height: 96)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.white)
            )
            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 6)
    }

    @ViewBuilder
    private var transitionedTile: some View {
        switch transitionKind {
        case .slide:
            tile.transition(.slide)
        case .scale:
            tile.transition(.scale)
        case .opacity:
            tile.transition(.opacity)
        case .asymmetric:
            tile.transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
        case .push:
            tile.transition(.push(from: .leading))
        }
    }

    private var currentAnimation: Animation {
        switch curve {
        case .easeInOut: return .easeInOut(duration: duration)
        case .spring:    return .spring(duration: duration)
        case .linear:    return .linear(duration: duration)
        }
    }

    private var animationCode: String {
        switch curve {
        case .easeInOut: return String(format: ".easeInOut(duration: %.2f)", duration)
        case .spring:    return String(format: ".spring(duration: %.2f)", duration)
        case .linear:    return String(format: ".linear(duration: %.2f)", duration)
        }
    }

    private var generatedCode: String {
        "withAnimation(\(animationCode)) {\n  show.toggle()\n}\n\nif show {\n  tile\n    \(transitionKind.code)\n}"
    }

    private func toggle() {
        withAnimation(currentAnimation) {
            isShowing.toggle()
        }
    }

    private func replay() {
        if isShowing {
            withAnimation(currentAnimation) { isShowing = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.15) {
                withAnimation(currentAnimation) { isShowing = true }
            }
        } else {
            withAnimation(currentAnimation) { isShowing = true }
        }
    }
}

// MARK: - Transition Kinds

private enum TransitionKind: String, CaseIterable {
    case slide = "Slide"
    case scale = "Scale"
    case opacity = "Opacity"
    case asymmetric = "Asymmetric"
    case push = "Push"

    var snippet: String {
        switch self {
        case .slide:      return ".slide"
        case .scale:      return ".scale"
        case .opacity:    return ".opacity"
        case .asymmetric: return ".asymmetric"
        case .push:       return ".push(from:)"
        }
    }

    var code: String {
        switch self {
        case .slide:   return ".transition(.slide)"
        case .scale:   return ".transition(.scale)"
        case .opacity: return ".transition(.opacity)"
        case .asymmetric:
            return ".transition(.asymmetric(\n      insertion: .move(edge: .trailing)\n        .combined(with: .opacity),\n      removal: .scale\n        .combined(with: .opacity)))"
        case .push:    return ".transition(.push(from: .leading))"
        }
    }

    var detail: String {
        switch self {
        case .slide:      return "Moves in from the leading edge, out toward trailing."
        case .scale:      return "Grows from and shrinks to the center."
        case .opacity:    return "Fades in and out in place."
        case .asymmetric: return "Different transitions for insertion and removal."
        case .push:       return "Slides in from an edge while pushing the old content out."
        }
    }
}

private enum CurveKind: String, CaseIterable {
    case easeInOut = "EaseInOut"
    case spring = "Spring"
    case linear = "Linear"
}

#Preview {
    NavigationStack { TransitionsView() }
}
