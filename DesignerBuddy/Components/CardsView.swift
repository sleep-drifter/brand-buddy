import SwiftUI
import UIKit

struct CardsView: View {
    @State private var expanded = false
    @State private var gradientPhase = false

    private let feedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                basicStylesSection
                expandableCardSection
                glassCardSection
            }
            .padding(16)
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Basic Styles

    private var basicStylesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(number: "—", title: "Basic Styles")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                plainCard
                elevatedCard
                borderedCard
                coloredCard
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var plainCard: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .frame(height: 56)
                .overlay(
                    Text("Aa")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                )
            Text("Plain")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var elevatedCard: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .frame(height: 56)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                .overlay(
                    Text("Aa")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                )
            Text("Elevated")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var borderedCard: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
                .overlay(
                    Text("Aa")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                )
            Text("Bordered")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var coloredCard: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.15))
                .frame(height: 56)
                .overlay(
                    Text("Aa")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                )
            Text("Colored")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - #034 Expandable Card

    private var expandableCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(number: "034", title: "Expandable Card")
            expandableCard
            Text("symbolEffect(.bounce) on chevron + UIImpactFeedbackGenerator for tactile response")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            feedback.prepare()
        }
    }

    private var expandableCard: some View {
        VStack(spacing: 0) {
            Button {
                if expanded {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                withAnimation(.spring(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Project Update")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Tap to expand")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .symbolEffect(.bounce, value: expanded)
                        .animation(.spring(duration: 0.2), value: expanded)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    Text("This card expands to reveal more content. Haptic feedback fires on open (.medium) and close (.light) to reinforce the interaction.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                    Text("Tap header to dismiss")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - #035 Glass Card — Layered

    private var glassCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(number: "035", title: "Glass Card — Layered")
            glassCardDemo
            Text(".ultraThinMaterial + RoundedRectangle stroke LinearGradient + animated MeshGradient background")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var glassCardDemo: some View {
        ZStack {
            animatedGradientBackground
                .clipShape(RoundedRectangle(cornerRadius: 12))
            glassCard
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                gradientPhase.toggle()
            }
        }
    }

    @ViewBuilder
    private var animatedGradientBackground: some View {
        if #available(iOS 18, *) {
            MeshGradientBackground(phase: gradientPhase)
                .frame(height: 220)
        } else {
            RadialGradientFallback(phase: gradientPhase)
                .frame(height: 220)
        }
    }

    private var glassCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(.primary)
            Text("Glass Card")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text("Frosted glass over a vivid animated gradient. .ultraThinMaterial refracts the shifting colors below.")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
                .blur(radius: 1)
                .padding(.horizontal, 12)
                .padding(.top, 1)
        }
        .padding(24)
    }

    // MARK: - Helpers

    private func sectionHeader(number: String, title: String) -> some View {
        HStack(spacing: 8) {
            if number != "—" {
                Text("#\(number)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - MeshGradient Background (iOS 18+)

@available(iOS 18, *)
private struct MeshGradientBackground: View {
    let phase: Bool

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [phase ? 0.0 : 0.1, 0.5], [phase ? 0.4 : 0.6, phase ? 0.4 : 0.6], [phase ? 1.0 : 0.9, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                phase ? Color(red: 0.55, green: 0.1, blue: 0.85) : Color(red: 0.4, green: 0.1, blue: 0.75),
                phase ? Color(red: 0.9, green: 0.2, blue: 0.6)  : Color(red: 0.85, green: 0.15, blue: 0.5),
                phase ? Color(red: 0.2, green: 0.3, blue: 0.95) : Color(red: 0.15, green: 0.25, blue: 0.9),
                phase ? Color(red: 0.0, green: 0.7, blue: 0.85) : Color(red: 0.05, green: 0.6, blue: 0.8),
                phase ? Color(red: 0.85, green: 0.3, blue: 0.7) : Color(red: 0.6, green: 0.15, blue: 0.8),
                phase ? Color(red: 0.1, green: 0.65, blue: 0.9) : Color(red: 0.05, green: 0.55, blue: 0.85),
                phase ? Color(red: 0.95, green: 0.4, blue: 0.1) : Color(red: 0.85, green: 0.35, blue: 0.05),
                phase ? Color(red: 0.6, green: 0.1, blue: 0.9)  : Color(red: 0.5, green: 0.05, blue: 0.85),
                phase ? Color(red: 0.0, green: 0.8, blue: 0.7)  : Color(red: 0.0, green: 0.7, blue: 0.65)
            ]
        )
    }
}

// MARK: - RadialGradient Fallback (iOS 17)

private struct RadialGradientFallback: View {
    let phase: Bool

    var body: some View {
        ZStack {
            Color(red: 0.3, green: 0.0, blue: 0.6)
            RadialGradient(
                colors: [Color(red: 0.9, green: 0.2, blue: 0.6), .clear],
                center: phase ? .topLeading : .topTrailing,
                startRadius: 0,
                endRadius: 200
            )
            RadialGradient(
                colors: [Color(red: 0.1, green: 0.5, blue: 0.95), .clear],
                center: phase ? .bottomTrailing : .bottomLeading,
                startRadius: 0,
                endRadius: 200
            )
            RadialGradient(
                colors: [Color(red: 0.95, green: 0.45, blue: 0.1), .clear],
                center: phase ? .bottom : .top,
                startRadius: 0,
                endRadius: 150
            )
        }
    }
}

#Preview {
    NavigationStack {
        CardsView()
    }
}
