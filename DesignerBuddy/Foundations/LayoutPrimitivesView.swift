import SwiftUI

// Merged into SpacingView ("Spacing & Layout"). Kept for compile compatibility.
typealias LayoutPrimitivesView = SpacingView

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
