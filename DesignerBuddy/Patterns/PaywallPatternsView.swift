import SwiftUI
import StoreKit

// Paywall Patterns — the purchase moment, twice over: a hand-built mock
// paywall for layout and copy reference (always renders), and the real
// StoreKit 2 views (SubscriptionStoreView, ProductView) backed by the
// BuddyStore.storekit test configuration wired into the scheme.

struct PaywallPatternsView: View {

    @State private var showMockPaywall = false

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("A paywall is a trust exercise: price, billing period, trial terms, and the way out all have to be legible *before* the purchase sheet appears. The system sheet handles payment — everything above it is yours to design.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Mock paywall ───────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Mock Paywall", tag: "Layout reference")) {
                Button("Present paywall sheet") { showMockPaywall = true }
                PaywallPlanPicker()
                    .padding(.vertical, 4)
                RefCaption("hero → features → plans → CTA → restore & legal")
                HIGNoteRow("The canonical order: what you get (features), what it costs (plans with period and trial), one prominent CTA, then restore and legal links — small but never hidden.")
            }

            // ── Real subscription store ────────────────────────────────────
            Section(header: SectionTagHeader(title: "SubscriptionStoreView", tag: "StoreKit 2")) {
                SubscriptionStoreView(groupID: "BUDDYPRO") {
                    VStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        Text("Buddy Pro")
                            .font(.title3.bold())
                        Text("Every playground, every reference, no limits.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                .subscriptionStoreControlStyle(.prominentPicker)
                .storeButton(.visible, for: .restorePurchases)
                .frame(height: 440)
                .listRowInsets(EdgeInsets())

                RefCaption("SubscriptionStoreView(groupID:) + BuddyStore.storekit")
                HIGNoteRow("This is live StoreKit against the local test configuration (already set in the shared scheme — Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Options if it shows no products). The system view supplies plan picking, pricing, trial badges, and purchase for free.")
            }

            // ── One-time purchase ──────────────────────────────────────────
            Section(header: SectionTagHeader(title: "ProductView", tag: "One-time")) {
                ProductView(id: "com.designerbuddy.pro.lifetime") {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(.purple)
                }
                .productViewStyle(.large)
                .padding(.vertical, 4)

                RefCaption("ProductView(id:) · .productViewStyle(.large)")
                HIGNoteRow("For a single non-consumable, ProductView renders localized price and the purchase button in one line of code — use it before building custom buy buttons.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                DoDontRow(good: true,  text: "State the full price and renewal period next to the CTA — \"3 days free, then $39.99/year\" beats a bare \"Continue\".")
                DoDontRow(good: true,  text: "Make **Restore Purchases** reachable from the paywall itself; locked-out paying customers are your angriest ones.")
                DoDontRow(good: false, text: "Don't preselect the most expensive plan while visually burying the alternatives — it reads as a dark pattern in review and in reviews.")
                DoDontRow(good: false, text: "Don't gate the close button behind a delay or hide it off-contrast; the paywall must always be dismissible.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                CodeBlockRow(code: """
                    SubscriptionStoreView(groupID: "BUDDYPRO") {
                        PaywallHero()   // your marketing content
                    }
                    .subscriptionStoreControlStyle(.prominentPicker)
                    .storeButton(.visible, for: .restorePurchases)

                    ProductView(id: "com.designerbuddy.pro.lifetime")
                        .productViewStyle(.large)
                    """)
            }
        }
        .navigationTitle("Paywall Patterns")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMockPaywall) {
            MockPaywallSheet()
        }
    }
}

// MARK: - Inline plan picker (mock)

private struct PaywallPlanPicker: View {
    @State private var selected = "yearly"

    var body: some View {
        VStack(spacing: 10) {
            planCard(id: "yearly", name: "Yearly", price: "$39.99/yr",
                     note: "7 days free · Save 33%", highlight: true)
            planCard(id: "monthly", name: "Monthly", price: "$4.99/mo",
                     note: "7 days free", highlight: false)
        }
    }

    private func planCard(id: String, name: String, price: String,
                          note: String, highlight: Bool) -> some View {
        Button {
            withAnimation(.snappy) { selected = id }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.subheadline.weight(.semibold))
                        if highlight {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue, in: Capsule())
                        }
                    }
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.subheadline.weight(.medium))
                Image(systemName: selected == id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected == id ? .blue : .secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected == id ? .blue : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mock paywall sheet

private struct MockPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String)] = [
        ("square.grid.2x2", "Every component and pattern page"),
        ("sparkles.rectangle.stack", "All shader playgrounds"),
        ("chart.bar.xaxis", "Full charts reference"),
        ("bookmark", "Unlimited bookmarks, synced"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: [.blue, .indigo],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 170)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.yellow)
                            Text("Designer Buddy Pro")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .padding(12)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.0) { icon, text in
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.blue)
                                Text(text)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    PaywallPlanPicker()
                }
                .padding(20)
            }

            VStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("Try free for 7 days")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                Text("Then $39.99/year · Cancel anytime in Settings")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    Button("Restore Purchases") {}
                    Button("Terms") {}
                    Button("Privacy") {}
                }
                .font(.caption2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    NavigationStack { PaywallPatternsView() }
}
