import SwiftUI

struct SpringPhysicsView: View {
    @State private var springAPI: SpringAPI = .modern
    @State private var duration: Double = 0.5
    @State private var bounce: Double = 0.3
    @State private var response: Double = 0.5
    @State private var dampingFraction: Double = 0.7
    @State private var animating = false
    @State private var offset: CGFloat = 0

    enum SpringAPI: String, CaseIterable {
        case modern = "spring(duration:bounce:)"
        case classic = "spring(response:dampingFraction:)"
    }

    var currentAnimation: Animation {
        switch springAPI {
        case .modern:
            return .spring(duration: duration, bounce: bounce)
        case .classic:
            return .spring(response: response, dampingFraction: dampingFraction)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    // Live preview
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.quaternary)
                            .frame(height: 200)

                        Circle()
                            .fill(.tint)
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 6)
                            .offset(y: animating ? -140 : -16)
                            .animation(currentAnimation, value: animating)
                    }
                    .onTapGesture {
                        animating.toggle()
                    }
                    .overlay(alignment: .center) {
                        if !animating {
                            Text("Tap to animate")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Button("Replay") {
                        animating = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            animating = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("API") {
                Picker("Spring API", selection: $springAPI) {
                    ForEach(SpringAPI.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.inline)
            }

            switch springAPI {
            case .modern:
                Section("Parameters") {
                    LabeledContent("duration: \(duration, specifier: "%.2f")s") {
                        Slider(value: $duration, in: 0.1...2.0)
                    }
                    LabeledContent("bounce: \(bounce, specifier: "%.2f")") {
                        Slider(value: $bounce, in: 0.0...1.0)
                    }
                }
                Section("Code") {
                    Text(".animation(.spring(duration: \(duration, specifier: "%.2f"), bounce: \(bounce, specifier: "%.2f")), value: animating)")
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                }

            case .classic:
                Section("Parameters") {
                    LabeledContent("response: \(response, specifier: "%.2f")") {
                        Slider(value: $response, in: 0.1...2.0)
                    }
                    LabeledContent("dampingFraction: \(dampingFraction, specifier: "%.2f")") {
                        Slider(value: $dampingFraction, in: 0.0...1.0)
                    }
                }
                Section("Code") {
                    Text(".animation(.spring(response: \(response, specifier: "%.2f"), dampingFraction: \(dampingFraction, specifier: "%.2f")), value: animating)")
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Presets") {
                ForEach(SpringPreset.all) { preset in
                    Button {
                        springAPI = .modern
                        duration = preset.duration
                        bounce = preset.bounce
                        animating = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animating = true }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name).font(.subheadline).foregroundStyle(.primary)
                                Text("duration: \(preset.duration, specifier: "%.2f"), bounce: \(preset.bounce, specifier: "%.2f")")
                                    .font(.mono(.caption)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(preset.feel).font(.caption).foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle("Spring Physics")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SpringPreset: Identifiable {
    let id = UUID()
    let name: String
    let duration: Double
    let bounce: Double
    let feel: String

    static let all: [SpringPreset] = [
        SpringPreset(name: "Snappy", duration: 0.3, bounce: 0.4, feel: "Quick & bouncy"),
        SpringPreset(name: "Default iOS", duration: 0.5, bounce: 0.3, feel: "Balanced"),
        SpringPreset(name: "Gentle", duration: 0.7, bounce: 0.1, feel: "Smooth"),
        SpringPreset(name: "Wobbly", duration: 0.6, bounce: 0.7, feel: "Playful"),
        SpringPreset(name: "Overdamped", duration: 0.8, bounce: 0.0, feel: "No bounce"),
        SpringPreset(name: "Fast Snap", duration: 0.2, bounce: 0.2, feel: "Instant"),
    ]
}

#Preview {
    NavigationStack {
        SpringPhysicsView()
    }
}
