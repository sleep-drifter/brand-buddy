import SwiftUI

struct SymbolEffectsView: View {
    @State private var selectedEffect: EffectOption = .bounce
    @State private var symbolName = "wifi"
    @State private var trigger = 0
    @State private var isActive = false
    @State private var byLayer = false
    @State private var showAlternate = false
    @State private var variableValue: Double = 1.0

    private let symbols = ["wifi", "speaker.wave.3.fill", "bell.fill", "heart.fill", "arrow.clockwise", "square.stack.3d.up.fill"]

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 260)

                        symbolView
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture { handleCanvasTap() }
                    .overlay(alignment: .bottom) {
                        Text(selectedEffect.isDiscrete ? "Tap to trigger" : "Tap to toggle")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 12)
                    }

                    if selectedEffect.isDiscrete {
                        Button(selectedEffect == .replace ? "Swap" : "Trigger") {
                            handleCanvasTap()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Toggle("Active", isOn: $isActive)
                            .toggleStyle(.button)
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

            Section("Effect") {
                PresetChipRow(
                    chips: EffectOption.allCases.map { effect in
                        PresetChip(
                            name: effect.rawValue,
                            detail: "\(effect.detail) \(effect.nature)",
                            code: effect.code
                        )
                    },
                    selectedID: effectSelection
                ) { _ in
                    trigger = 0
                    isActive = false
                    showAlternate = false
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                Picker("Symbol", selection: $symbolName) {
                    ForEach(symbols, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)

                if selectedEffect.supportsByLayer {
                    Toggle("byLayer", isOn: $byLayer)
                }

                if selectedEffect == .variableColor {
                    LabeledContent("variableValue: \(variableValue, specifier: "%.2f")") {
                        Slider(value: $variableValue, in: 0...1)
                    }
                }
            } header: {
                Text("Controls")
            } footer: {
                Text(".byLayer applies the effect to each symbol path layer independently, creating a staggered sequential animation.")
            }

            Section {
                NavigationLink("Open Symbol Playground") {
                    SymbolPlaygroundView()
                }
            } footer: {
                Text("The playground adds color palettes, rendering modes, symbol search, and code export.")
            }
        }
        .navigationTitle("Symbol Effects")
        .navigationBarTitleDisplayMode(.large)
    }

    private var effectSelection: Binding<String?> {
        Binding(
            get: { selectedEffect.rawValue },
            set: { name in
                guard let name, let effect = EffectOption(rawValue: name) else { return }
                selectedEffect = effect
            }
        )
    }

    // MARK: - Canvas

    @ViewBuilder
    private var symbolView: some View {
        switch selectedEffect {
        case .bounce:
            if byLayer {
                baseSymbol.symbolEffect(.bounce.byLayer, value: trigger)
            } else {
                baseSymbol.symbolEffect(.bounce, value: trigger)
            }
        case .pulse:
            baseSymbol.symbolEffect(.pulse, value: trigger)
        case .wiggle:
            if byLayer {
                baseSymbol.symbolEffect(.wiggle.byLayer, value: trigger)
            } else {
                baseSymbol.symbolEffect(.wiggle, value: trigger)
            }
        case .rotate:
            if byLayer {
                baseSymbol.symbolEffect(.rotate.byLayer, value: trigger)
            } else {
                baseSymbol.symbolEffect(.rotate, value: trigger)
            }
        case .breathe:
            if byLayer {
                baseSymbol.symbolEffect(.breathe.byLayer, isActive: isActive)
            } else {
                baseSymbol.symbolEffect(.breathe, isActive: isActive)
            }
        case .pulseContinuous:
            baseSymbol.symbolEffect(.pulse, isActive: isActive)
        case .variableColor:
            baseSymbol.symbolEffect(.variableColor.iterative.reversing, isActive: isActive)
        case .appear:
            if byLayer {
                baseSymbol.symbolEffect(.appear.byLayer, isActive: isActive)
            } else {
                baseSymbol.symbolEffect(.appear, isActive: isActive)
            }
        case .disappear:
            if byLayer {
                baseSymbol.symbolEffect(.disappear.byLayer, isActive: isActive)
            } else {
                baseSymbol.symbolEffect(.disappear, isActive: isActive)
            }
        case .replace:
            Image(systemName: showAlternate ? "pause.fill" : "play.fill")
                .font(.system(size: 90))
                .foregroundStyle(.tint)
                .contentTransition(.symbolEffect(.replace))
                .animation(.default, value: showAlternate)
        }
    }

    private var baseSymbol: some View {
        Image(systemName: symbolName, variableValue: variableValue)
            .font(.system(size: 90))
            .foregroundStyle(.tint)
    }

    private func handleCanvasTap() {
        switch selectedEffect {
        case .replace:
            showAlternate.toggle()
        default:
            if selectedEffect.isDiscrete {
                trigger += 1
            } else {
                isActive.toggle()
            }
        }
    }

    // MARK: - Code

    private var generatedCode: String {
        switch selectedEffect {
        case .bounce:
            return wrap(byLayer ? ".symbolEffect(.bounce.byLayer, value: trigger)" : ".symbolEffect(.bounce, value: trigger)")
        case .pulse:
            return wrap(".symbolEffect(.pulse, value: trigger)")
        case .wiggle:
            return wrap(byLayer ? ".symbolEffect(.wiggle.byLayer, value: trigger)" : ".symbolEffect(.wiggle, value: trigger)")
        case .rotate:
            return wrap(byLayer ? ".symbolEffect(.rotate.byLayer, value: trigger)" : ".symbolEffect(.rotate, value: trigger)")
        case .breathe:
            return wrap(byLayer ? ".symbolEffect(.breathe.byLayer, isActive: isActive)" : ".symbolEffect(.breathe, isActive: isActive)")
        case .pulseContinuous:
            return wrap(".symbolEffect(.pulse, isActive: isActive)")
        case .variableColor:
            let value = String(format: "%.2f", variableValue)
            return "Image(systemName: \"\(symbolName)\", variableValue: \(value))\n    .symbolEffect(.variableColor.iterative.reversing, isActive: isActive)"
        case .appear:
            return wrap(byLayer ? ".symbolEffect(.appear.byLayer, isActive: isActive)" : ".symbolEffect(.appear, isActive: isActive)")
        case .disappear:
            return wrap(byLayer ? ".symbolEffect(.disappear.byLayer, isActive: isActive)" : ".symbolEffect(.disappear, isActive: isActive)")
        case .replace:
            return "Image(systemName: playing ? \"pause.fill\" : \"play.fill\")\n    .contentTransition(.symbolEffect(.replace))\n    .animation(.default, value: playing)"
        }
    }

    private func wrap(_ effect: String) -> String {
        "Image(systemName: \"\(symbolName)\")\n    \(effect)"
    }
}

// MARK: - Effect Options

private enum EffectOption: String, CaseIterable {
    case bounce = ".bounce"
    case pulse = ".pulse"
    case wiggle = ".wiggle"
    case rotate = ".rotate"
    case breathe = ".breathe"
    case pulseContinuous = ".pulse (continuous)"
    case variableColor = ".variableColor"
    case appear = ".appear"
    case disappear = ".disappear"
    case replace = ".replace"

    var isDiscrete: Bool {
        switch self {
        case .bounce, .pulse, .wiggle, .rotate, .replace: return true
        default: return false
        }
    }

    var supportsByLayer: Bool {
        switch self {
        case .bounce, .wiggle, .rotate, .breathe, .appear, .disappear: return true
        default: return false
        }
    }

    var detail: String {
        switch self {
        case .bounce:          return "Scales up and settles back — great for taps and alerts."
        case .pulse:           return "Fades opacity out and back in a single beat."
        case .wiggle:          return "Rocks side to side to demand attention."
        case .rotate:          return "Spins the symbol once around its anchor."
        case .breathe:         return "Gently scales in and out while active."
        case .pulseContinuous: return "Continuous pulse, distinct from .breathe."
        case .variableColor:   return "Cycles variable layers — waveforms, wifi bars."
        case .appear:          return "Animates the symbol into view when toggled."
        case .disappear:       return "Animates the symbol out of view when toggled."
        case .replace:         return "Most common real-world use — toggle play/pause state."
        }
    }

    var nature: String {
        isDiscrete ? "Discrete — plays once per trigger." : "Indefinite — runs while active."
    }

    var code: String {
        switch self {
        case .bounce:          return ".symbolEffect(.bounce, value: trigger)"
        case .pulse:           return ".symbolEffect(.pulse, value: trigger)"
        case .wiggle:          return ".symbolEffect(.wiggle, value: trigger)"
        case .rotate:          return ".symbolEffect(.rotate, value: trigger)"
        case .breathe:         return ".symbolEffect(.breathe, isActive: isActive)"
        case .pulseContinuous: return ".symbolEffect(.pulse, isActive: isActive)"
        case .variableColor:   return ".symbolEffect(.variableColor.iterative.reversing, isActive: isActive)"
        case .appear:          return ".symbolEffect(.appear, isActive: isActive)"
        case .disappear:       return ".symbolEffect(.disappear, isActive: isActive)"
        case .replace:         return ".contentTransition(.symbolEffect(.replace))"
        }
    }
}

#Preview {
    NavigationStack { SymbolEffectsView() }
}
