import SwiftUI

struct TransitionsView: View {
    @State private var isShowing = true
    @State private var transitionKind: TransitionKind = .slide
    @State private var duration: Double = 0.4
    @State private var curve: CurveKind = .easeInOut

    var body: some View {
        List {
            Section("Controls") {
                LabeledContent("duration: \(duration, specifier: "%.2f")s") {
                    Slider(value: $duration, in: 0.1...1.5)
                }

                Picker("Curve", selection: $curve) {
                    ForEach(CurveKind.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }

            Section("Transition Types") {
                PresetChipRow(
                    chips: TransitionKind.allCases.map { kind in
                        PresetChip(name: kind.rawValue, detail: kind.detail)
                    },
                    selectedID: transitionSelection
                ) { _ in
                    replay()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .pinnedPreview(entry: "Transitions") {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.quaternary)
                    .frame(height: 190)

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
            .overlay(alignment: .bottomTrailing) {
                Button(isShowing ? "Hide" : "Show") {
                    toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(10)
            }
        }
        .navigationTitle("Transitions")
    }

    private var transitionSelection: Binding<String?> {
        Binding(
            get: { transitionKind.rawValue },
            set: { name in
                guard let name, let kind = TransitionKind(rawValue: name) else { return }
                transitionKind = kind
            }
        )
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
    case easeInOut = "Ease In Out"
    case spring = "Spring"
    case linear = "Linear"
}

#Preview {
    NavigationStack { TransitionsView() }
        .environmentObject(PinsStore())
}
