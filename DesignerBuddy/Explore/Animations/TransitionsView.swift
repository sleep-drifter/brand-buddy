import SwiftUI

struct TransitionsView: View {
    @State private var showSlide = false
    @State private var showScale = false
    @State private var showOpacity = false
    @State private var showAsymmetric = false
    @State private var showPush = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Slide
                transitionCard(
                    title: ".slide",
                    icon: "arrow.left.arrow.right.square",
                    color: .blue,
                    isShowing: $showSlide,
                    code: ".transition(.slide)"
                ) {
                    if showSlide {
                        sampleBox(color: .blue, label: "Slide")
                            .transition(.slide)
                    }
                }

                // MARK: - Scale
                transitionCard(
                    title: ".scale",
                    icon: "arrow.up.left.and.arrow.down.right",
                    color: .purple,
                    isShowing: $showScale,
                    code: ".transition(.scale)"
                ) {
                    if showScale {
                        sampleBox(color: .purple, label: "Scale")
                            .transition(.scale)
                    }
                }

                // MARK: - Opacity
                transitionCard(
                    title: ".opacity",
                    icon: "circle.dashed",
                    color: .green,
                    isShowing: $showOpacity,
                    code: ".transition(.opacity)"
                ) {
                    if showOpacity {
                        sampleBox(color: .green, label: "Opacity")
                            .transition(.opacity)
                    }
                }

                // MARK: - Asymmetric
                transitionCard(
                    title: ".asymmetric",
                    icon: "arrow.up.right.and.arrow.down.left",
                    color: .orange,
                    isShowing: $showAsymmetric,
                    code: ".transition(.asymmetric(insertion: .slide, removal: .scale))"
                ) {
                    if showAsymmetric {
                        sampleBox(color: .orange, label: "Asymmetric")
                            .transition(.asymmetric(insertion: .slide, removal: .scale))
                    }
                }

                // MARK: - Push
                transitionCard(
                    title: ".push(from:)",
                    icon: "arrow.right.square",
                    color: .pink,
                    isShowing: $showPush,
                    code: ".transition(.push(from: .trailing))"
                ) {
                    if showPush {
                        sampleBox(color: .pink, label: "Push")
                            .transition(.push(from: .trailing))
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Transitions")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func transitionCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        isShowing: Binding<Bool>,
        code: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                Button(isShowing.wrappedValue ? "Hide" : "Show") {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isShowing.wrappedValue.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(color)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.07))
                    .frame(height: 70)
                content()
            }
            Text(code)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func sampleBox(color: Color, label: String) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color.gradient)
            .frame(width: 80, height: 44)
            .overlay(Text(label).font(.caption.weight(.semibold)).foregroundStyle(.white))
    }
}

#Preview {
    NavigationStack { TransitionsView() }
}
