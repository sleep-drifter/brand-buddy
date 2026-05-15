import SwiftUI

struct SwipeDragView: View {
    // MARK: - Drag state
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var lastVelocity: CGSize = .zero

    // MARK: - Swipe detection
    @State private var swipeDirection = "—"

    // MARK: - Velocity dismiss simulation
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var cardDismissed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - DragGesture basics
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("DragGesture", systemImage: "hand.draw")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 180)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 48, height: 48)
                            .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                            .offset(dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        isDragging = false
                                        lastVelocity = value.velocity
                                        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                                            dragOffset = .zero
                                        }
                                    }
                            )
                        if !isDragging {
                            Text("Drag the dot")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .offset(y: 60)
                        } else {
                            Text("x: \(Int(dragOffset.width))  y: \(Int(dragOffset.height))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .offset(y: 60)
                        }
                    }
                    if lastVelocity != .zero {
                        Text("Release velocity — x: \(Int(lastVelocity.width)) y: \(Int(lastVelocity.height)) pt/s")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("DragGesture().translation tracks offset from start; .velocity is available on release (iOS 17+).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Directional swipe detection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Directional Swipe Detection", systemImage: "arrow.left.and.right")
                            .font(.headline)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.1))
                        .frame(height: 100)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: directionIcon(swipeDirection))
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                Text(swipeDirection)
                                    .font(.subheadline.weight(.medium))
                            }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    let h = value.translation.width
                                    let v = value.translation.height
                                    if abs(h) > abs(v) {
                                        swipeDirection = h > 0 ? "Right" : "Left"
                                    } else {
                                        swipeDirection = v > 0 ? "Down" : "Up"
                                    }
                                }
                        )
                    Text("Compare the absolute horizontal vs. vertical translation on .onEnded to determine the dominant axis.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Velocity-based dismiss
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Velocity-Based Dismiss", systemImage: "arrow.up.to.line")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.gray.opacity(0.08))
                            .frame(height: 140)

                        if cardDismissed {
                            Button("Bring it back") {
                                cardOffset = 0
                                cardOpacity = 1
                                cardDismissed = false
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.orange)
                                .frame(width: 120, height: 60)
                                .overlay(Text("Swipe up fast").font(.caption).foregroundStyle(.white))
                                .offset(y: cardOffset)
                                .opacity(cardOpacity)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            cardOffset = min(0, value.translation.height)
                                        }
                                        .onEnded { value in
                                            let shouldDismiss = value.velocity.height < -300 || value.translation.height < -50
                                            if shouldDismiss {
                                                withAnimation(.easeOut(duration: 0.25)) {
                                                    cardOffset = -200
                                                    cardOpacity = 0
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    cardDismissed = true
                                                }
                                            } else {
                                                withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                                                    cardOffset = 0
                                                }
                                            }
                                        }
                                )
                        }
                    }
                    Text("Dismiss if velocity.height < −300 pt/s OR translation > 50 pt. Small flicks trigger dismiss even without large distance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Swipe & Drag")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func directionIcon(_ direction: String) -> String {
        switch direction {
        case "Left":  return "arrow.left"
        case "Right": return "arrow.right"
        case "Up":    return "arrow.up"
        case "Down":  return "arrow.down"
        default:      return "hand.draw"
        }
    }
}

#Preview {
    NavigationStack { SwipeDragView() }
}
