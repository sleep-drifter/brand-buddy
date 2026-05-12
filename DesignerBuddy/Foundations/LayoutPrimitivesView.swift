import SwiftUI

struct LayoutPrimitivesView: View {
    var body: some View {
        List {
            Section("Stack Alignment") {
                StackAlignmentDemo()
            }
            Section("Frame Behavior") {
                FrameDemo()
            }
            Section("Padding") {
                PaddingDemo()
            }
            Section("Safe Area") {
                SafeAreaDemo()
            }
        }
        .navigationTitle("Layout Primitives")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StackAlignmentDemo: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach([(HorizontalAlignment.leading, "leading"),
                     (HorizontalAlignment.center, "center"),
                     (HorizontalAlignment.trailing, "trailing")], id: \.1) { alignment, label in
                VStack(alignment: alignment, spacing: 4) {
                    Rectangle().fill(.tint.opacity(0.3)).frame(width: 180, height: 6).clipShape(Capsule())
                    Rectangle().fill(.tint.opacity(0.5)).frame(width: 120, height: 6).clipShape(Capsule())
                    Rectangle().fill(.tint).frame(width: 80, height: 6).clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Text(".\(label)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct FrameDemo: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("maxWidth: .infinity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            HStack(spacing: 8) {
                ForEach(["min", "ideal", "max"], id: \.self) { label in
                    Text(label)
                        .font(.mono(.caption2))
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PaddingDemo: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach([4.0, 8.0, 16.0, 24.0], id: \.self) { padding in
                VStack(spacing: 4) {
                    Text("Ag")
                        .font(.body)
                        .padding(padding)
                        .background(.tint.opacity(0.15))
                        .overlay(
                            Rectangle().strokeBorder(.tint, lineWidth: 1)
                        )
                    Text("\(Int(padding))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct SafeAreaDemo: View {
    var body: some View {
        Text("Safe area insets are covered in More → Safe Areas with full device maps.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
    }
}

struct AnimationCurvesView: View {
    var body: some View {
        Text("Animation curves — coming soon. See More → Spring Physics for the spring playground.")
            .font(.body)
            .foregroundStyle(.secondary)
            .padding()
            .navigationTitle("Animation Curves")
    }
}

struct SFSymbolsView: View {
    @State private var search = ""
    @State private var weight: Font.Weight = .regular

    private let commonSymbols = [
        "star", "heart", "house", "person", "gear", "bell",
        "magnifyingglass", "plus", "minus", "xmark", "checkmark",
        "arrow.right", "arrow.left", "arrow.up", "arrow.down",
        "chevron.right", "chevron.left", "chevron.up", "chevron.down",
        "square.and.arrow.up", "square.and.arrow.down", "trash",
        "pencil", "folder", "doc", "calendar", "clock",
        "map", "location", "phone", "envelope", "message",
        "wifi", "battery.100", "camera", "photo", "mic",
        "speaker.wave.2", "play.fill", "pause.fill", "stop.fill",
        "forward.fill", "backward.fill", "shuffle", "repeat",
        "lock", "key", "shield", "eye", "eye.slash",
        "list.bullet", "grid", "rectangle.split.3x1",
        "chart.bar", "chart.pie", "waveform", "bubble.left",
    ]

    var filtered: [String] {
        search.isEmpty ? commonSymbols : commonSymbols.filter { $0.contains(search.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Weight", selection: $weight) {
                Text("Light").tag(Font.Weight.light)
                Text("Regular").tag(Font.Weight.regular)
                Text("Medium").tag(Font.Weight.medium)
                Text("Bold").tag(Font.Weight.bold)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(filtered, id: \.self) { symbol in
                        VStack(spacing: 6) {
                            Image(systemName: symbol)
                                .font(.system(size: 24, weight: weight))
                                .frame(width: 44, height: 44)
                            Text(symbol)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
                .padding()
            }
        }
        .searchable(text: $search, prompt: "Filter symbols")
        .navigationTitle("SF Symbols")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        LayoutPrimitivesView()
    }
}
