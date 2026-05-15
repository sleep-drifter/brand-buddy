import SwiftUI

struct TapLongPressView: View {
    @State private var tapCount = 0
    @State private var doubleTapCount = 0
    @State private var longPressActive = false
    @State private var longPressCount = 0
    @State private var simultaneousResult = ""
    @State private var sequentialResult = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Tap Gesture
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("TapGesture", systemImage: "hand.tap")
                            .font(.headline)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 80)
                        .overlay(
                            VStack(spacing: 4) {
                                Text("Tap me")
                                    .font(.subheadline.weight(.medium))
                                Text("Taps: \(tapCount)   Double-taps: \(doubleTapCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )
                        .onTapGesture(count: 2) {
                            doubleTapCount += 1
                        }
                        .onTapGesture {
                            tapCount += 1
                        }
                    Text("Single tap and double tap are recognized independently. Note: add the double-tap gesture first so SwiftUI checks it before the single-tap fallback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Long Press Gesture
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("LongPressGesture", systemImage: "hand.tap.fill")
                            .font(.headline)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(longPressActive ? Color.orange.opacity(0.3) : Color.orange.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            VStack(spacing: 4) {
                                Text(longPressActive ? "Holding..." : "Hold me")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(longPressActive ? .orange : .primary)
                                Text("Triggered: \(longPressCount)×")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )
                        .animation(.easeInOut(duration: 0.2), value: longPressActive)
                        .gesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onChanged { pressing in
                                    longPressActive = pressing
                                }
                                .onEnded { _ in
                                    longPressCount += 1
                                    longPressActive = false
                                }
                        )
                    Text("minimumDuration: 0.5 seconds. The .onChanged fires while pressing begins; .onEnded fires when the minimum duration is met.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Simultaneous Gestures
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Simultaneous Gestures", systemImage: "hand.raised.fingers.spread")
                            .font(.headline)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.12))
                        .frame(height: 80)
                        .overlay(
                            Text(simultaneousResult.isEmpty ? "Tap or hold" : simultaneousResult)
                                .font(.subheadline)
                                .foregroundStyle(simultaneousResult.isEmpty ? .secondary : .primary)
                        )
                        .gesture(
                            TapGesture()
                                .simultaneously(with: LongPressGesture(minimumDuration: 0.6))
                                .onEnded { value in
                                    if value.second == true {
                                        simultaneousResult = "Long press detected"
                                    } else {
                                        simultaneousResult = "Tap detected"
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        simultaneousResult = ""
                                    }
                                }
                        )
                    Text(".simultaneously(with:) lets both gestures run at the same time. The combined value carries both results.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Sequential Gestures
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Sequential Gestures", systemImage: "arrow.right.circle")
                            .font(.headline)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green.opacity(0.12))
                        .frame(height: 80)
                        .overlay(
                            Text(sequentialResult.isEmpty ? "Long-press then drag" : sequentialResult)
                                .font(.subheadline)
                                .foregroundStyle(sequentialResult.isEmpty ? .secondary : .primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        )
                        .gesture(
                            LongPressGesture(minimumDuration: 0.4)
                                .sequenced(before: DragGesture())
                                .onEnded { value in
                                    switch value {
                                    case .second(true, let drag):
                                        let dist = drag?.translation.width ?? 0
                                        sequentialResult = "Dragged \(Int(dist))pt after long press"
                                    default:
                                        sequentialResult = "Long-press triggered"
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        sequentialResult = ""
                                    }
                                }
                        )
                    Text(".sequenced(before:) requires the first gesture to succeed before the second begins — classic drag-to-reorder pattern.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Tap & Long Press")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { TapLongPressView() }
}
