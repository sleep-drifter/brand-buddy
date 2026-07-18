import SwiftUI

struct MatchedGeometryView: View {
    @Namespace private var heroNamespace
    @State private var selectedItem: Item? = nil
    @Namespace private var tabNamespace
    @State private var selectedTab = 0
    @Namespace private var pillNamespace
    @State private var pillExpanded = false
    @Namespace private var iconNamespace
    @State private var iconExpanded = false

    private let tabItems = ["Home", "Search", "Library", "Profile"]

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

                // MARK: - Tab Bar Indicator Demo
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Tab Bar Indicator", systemImage: "rectangle.on.rectangle")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        HStack {
                            ForEach(tabItems.indices, id: \.self) { i in
                                Button {
                                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) { selectedTab = i }
                                } label: {
                                    Text(tabItems[i])
                                        .font(.subheadline.weight(selectedTab == i ? .semibold : .regular))
                                        .foregroundStyle(selectedTab == i ? .primary : .secondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background {
                                            if selectedTab == i {
                                                Capsule()
                                                    .fill(.regularMaterial)
                                                    .matchedGeometryEffect(id: "tab", in: tabNamespace)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(.quaternary, in: Capsule())
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    Text("A shared capsule slides between tabs — both states are geometry-matched")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Pill → Card Expansion Demo
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Pill → Card Expansion", systemImage: "rectangle.compress.vertical")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        if pillExpanded {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.pink)
                                        .matchedGeometryEffect(id: "pillIcon", in: pillNamespace)
                                    VStack(alignment: .leading) {
                                        Text("Now Playing").font(.headline)
                                        Text("Designer Buddy Radio").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.15)) { pillExpanded = false }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.pink)
                                    .matchedGeometryEffect(id: "pillIcon", in: pillNamespace)
                                Text("Now Playing").font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.4, bounce: 0.15)) { pillExpanded = true }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    Text("Mirrors iOS Music mini-player expand pattern")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Icon → Full Bleed Hero Demo
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Icon → Full Bleed Hero", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        if iconExpanded {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.teal.gradient)
                                    .matchedGeometryEffect(id: "icon", in: iconNamespace)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                Image(systemName: "star.fill")
                                    .font(.system(size: 56))
                                    .foregroundStyle(.white)
                                    .matchedGeometryEffect(id: "iconSymbol", in: iconNamespace)
                            }
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.4, bounce: 0.15)) { iconExpanded = false }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.teal.gradient)
                                    .matchedGeometryEffect(id: "icon", in: iconNamespace)
                                    .frame(width: 60, height: 60)
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .matchedGeometryEffect(id: "iconSymbol", in: iconNamespace)
                            }
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.4, bounce: 0.15)) { iconExpanded = true }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    Text("SF Symbol morphs from icon to full-bleed hero banner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
