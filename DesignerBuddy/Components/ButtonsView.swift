import SwiftUI

struct ButtonsView: View {
    @State private var isLoading = false

    var body: some View {
        List {
            Section("Style Matrix") {
                StyleMatrixSection()
            }
            Section("Size Scale") {
                SizeScaleSection()
            }
            Section("States") {
                StatesSection(isLoading: $isLoading)
            }
            Section("With Icons") {
                IconButtonsSection()
            }
            Section("Destructive") {
                Button("Delete Account", role: .destructive) {}
                Button(role: .destructive) {} label: {
                    Label("Remove Item", systemImage: "trash")
                }
            }
            Section("Full Width") {
                Button("Full Width Filled") {}
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                Button("Full Width Bordered") {}
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Buttons")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct StyleMatrixSection: View {
    private let styles: [(name: String, style: AnyButtonStyle)] = [
        ("borderedProminent", AnyButtonStyle(.borderedProminent)),
        ("bordered", AnyButtonStyle(.bordered)),
        ("borderless", AnyButtonStyle(.borderless)),
        ("plain", AnyButtonStyle(.plain)),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(styles, id: \.name) { item in
                    VStack(spacing: 8) {
                        Button("Button") {}
                            .buttonStyle(item.style)
                        Text(item.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct SizeScaleSection: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach([ControlSize.mini, .small, .regular, .large], id: \.self) { size in
                    VStack(spacing: 8) {
                        Button("Button") {}
                            .buttonStyle(.borderedProminent)
                            .controlSize(size)
                        Text(size.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct StatesSection: View {
    @Binding var isLoading: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Button("Normal") {}
                        .buttonStyle(.borderedProminent)
                    Text("normal").font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                VStack(spacing: 6) {
                    Button("Disabled") {}
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                    Text("disabled").font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                VStack(spacing: 6) {
                    Button {
                        isLoading.toggle()
                    } label: {
                        if isLoading {
                            HStack(spacing: 6) {
                                ProgressView().tint(.white)
                                Text("Loading")
                            }
                        } else {
                            Text("Tap me")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Text("loading").font(.mono(.caption2)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct IconButtonsSection: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
                Button { } label: { Label("Add", systemImage: "plus") }
                    .buttonStyle(.bordered)
                Button { } label: { Image(systemName: "heart") }
                    .buttonStyle(.bordered)
            }
            HStack(spacing: 12) {
                Button { } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered)
                    .labelStyle(.iconOnly)
                Button { } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered)
                    .labelStyle(.titleOnly)
                Button { } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered)
                    .labelStyle(.titleAndIcon)
            }
            HStack(spacing: 6) {
                Text(".iconOnly").font(.mono(.caption2)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Text(".titleOnly").font(.mono(.caption2)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Text(".titleAndIcon").font(.mono(.caption2)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let base: any ButtonStyle

    init(_ style: some ButtonStyle) { self.base = style }

    func makeBody(configuration: Configuration) -> some View {
        AnyView(base.makeBody(configuration: configuration))
    }
}

extension ControlSize {
    var label: String {
        switch self {
        case .mini: return ".mini"
        case .small: return ".small"
        case .regular: return ".regular"
        case .large: return ".large"
        case .extraLarge: return ".extraLarge"
        @unknown default: return "unknown"
        }
    }
}

#Preview {
    NavigationStack {
        ButtonsView()
    }
}
