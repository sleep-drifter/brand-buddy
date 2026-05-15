import SwiftUI

struct MatchedGeometryView: View {
    @Namespace private var heroNamespace
    @State private var selectedItem: Item? = nil

    private let items: [Item] = [
        Item(id: "1", color: .blue,   icon: "star.fill",       title: "Favorites"),
        Item(id: "2", color: .purple, icon: "heart.fill",      title: "Liked"),
        Item(id: "3", color: .orange, icon: "flame.fill",      title: "Trending"),
        Item(id: "4", color: .teal,   icon: "bolt.fill",       title: "Quick"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Explanation card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("matchedGeometryEffect", systemImage: "rectangle.on.rectangle.angled")
                            .font(.headline)
                        Spacer()
                    }
                    Text("Tap any card in the grid to expand it into a hero view. The animation is driven by matchedGeometryEffect — SwiftUI interpolates the frame between the two views automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Grid (shown when nothing is selected)
                if selectedItem == nil {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(items) { item in
                            Button {
                                withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                                    selectedItem = item
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(item.color.gradient)
                                    .matchedGeometryEffect(id: item.id, in: heroNamespace)
                                    .frame(height: 100)
                                    .overlay(
                                        VStack(spacing: 6) {
                                            Image(systemName: item.icon)
                                                .font(.title)
                                                .foregroundStyle(.white)
                                            Text(item.title)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.white)
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                // MARK: - Detail (hero destination)
                if let item = selectedItem {
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(item.color.gradient)
                            .matchedGeometryEffect(id: item.id, in: heroNamespace)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 52))
                                        .foregroundStyle(.white)
                                    Text(item.title)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            )

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hero Detail")
                                .font(.headline)
                            Text("The card animates from its grid position to fill this expanded view. matchedGeometryEffect(id:in:) anchors both views to the same geometry namespace — SwiftUI handles the frame interpolation.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Back to Grid") {
                                withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                                    selectedItem = nil
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(item.color)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(20)
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }

                // MARK: - Usage note
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Key Rules", systemImage: "info.circle")
                            .font(.headline)
                        Spacer()
                    }
                    VStack(spacing: 6) {
                        ruleRow("Both views must share the same @Namespace.")
                        ruleRow("Only one view with a given id should be visible at a time.")
                        ruleRow("Wrap the state toggle in withAnimation for the morph.")
                        ruleRow("Works across any view hierarchy — list rows to modal sheets.")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Matched Geometry")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .padding(.top, 1)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Model

private struct Item: Identifiable {
    let id: String
    let color: Color
    let icon: String
    let title: String
}

#Preview {
    NavigationStack { MatchedGeometryView() }
}
