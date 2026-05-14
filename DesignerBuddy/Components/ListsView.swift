import SwiftUI

// MARK: - ListsView (#010 — inline mock cards for each list style)

struct ListsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // MARK: Plain
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plain")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(".listStyle(.plain)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(["Row 1", "Row 2", "Row 3", "Row 4"], id: \.self) { label in
                            HStack {
                                Text(label)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    .background(Color(.systemBackground))
                }

                // MARK: Inset Grouped
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inset Grouped")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(".listStyle(.insetGrouped)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(["Section A", "Section B"], id: \.self) { section in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(section)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 4)
                                VStack(spacing: 0) {
                                    ForEach(1...3, id: \.self) { i in
                                        HStack {
                                            Text("Row \(i)")
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 11)
                                        if i < 3 {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(.secondarySystemGroupedBackground),
                                             in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                }

                // MARK: Grouped
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grouped")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(".listStyle(.grouped)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(["Section A", "Section B"], id: \.self) { section in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(section)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 20)
                                    .padding(.bottom, 6)
                                VStack(spacing: 0) {
                                    ForEach(1...3, id: \.self) { i in
                                        HStack {
                                            Text("Row \(i)")
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 11)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        if i < 3 {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }

                // MARK: Row Types — real interactive List
                Text("Row Types")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 4)

                RowVariantsList()
                    .frame(height: 520)
            }
            .padding(.vertical)
        }
        .navigationTitle("Lists & Tables")
        .navigationBarTitleDisplayMode(.large)
    }
}

// Extracted so it can have its own @State
private struct RowVariantsList: View {
    @State private var checked = false

    var body: some View {
        List {
            Section("Basic") {
                Text("Simple text row")
                HStack {
                    Text("Label")
                    Spacer()
                    Text("Value").foregroundStyle(.secondary)
                }
                NavigationLink("With disclosure indicator") { Text("Detail") }
            }

            Section("With Icons") {
                Label("Maps", systemImage: "map")
                Label("Settings", systemImage: "gear")
                    .foregroundStyle(.primary)
                Label {
                    VStack(alignment: .leading) {
                        Text("Title")
                        Text("Subtitle").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }

            Section("Subtitle") {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Primary text")
                    Text("Secondary subtitle text").font(.footnote).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Another item")
                    Text("With a longer subtitle that might wrap to two lines on smaller devices")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("With Controls") {
                Toggle("Toggle in row", isOn: $checked)
                Stepper("Stepper in row", value: .constant(3), in: 0...10)
                Button("Button row") {}
            }

            Section("Swipe Actions") {
                Text("Swipe left →")
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {} label: { Label("Delete", systemImage: "trash") }
                        Button {} label: { Label("Archive", systemImage: "archivebox") }
                            .tint(.orange)
                    }
                Text("← Swipe right")
                    .swipeActions(edge: .leading) {
                        Button {} label: { Label("Flag", systemImage: "flag") }
                            .tint(.yellow)
                    }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDisabled(true)
    }
}

// MARK: - GridsView (unchanged)

struct GridsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("LazyVGrid — 3 columns")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(0..<9) { i in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.tint.opacity(0.2))
                            .frame(height: 80)
                            .overlay(Text("\(i + 1)").font(.caption))
                    }
                }
                .padding(.horizontal)

                Text("LazyVGrid — 2 columns (adaptive)")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(0..<6) { i in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.tint.opacity(0.15))
                            .frame(height: 100)
                            .overlay(Text("Item \(i + 1)").font(.caption))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Grids")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - ScrollViewsView (#011 — inline demos for all scroll variants)

struct ScrollViewsView: View {
    var body: some View {
        List {

            // 1. Vertical
            Section("Vertical") {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(0..<8) { i in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hue: Double(i) / 8, saturation: 0.5, brightness: 0.85))
                                .frame(height: 56)
                                .overlay(Text("Item \(i + 1)").font(.subheadline).bold())
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 260)
            }

            // 2. Horizontal — basic
            Section("Horizontal — basic") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<10) { i in
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.tint.opacity(0.15))
                                .frame(width: 120, height: 80)
                                .overlay(Text("Card \(i + 1)").font(.caption))
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            }

            // 3. Horizontal — snapping
            Section("Horizontal — snapping") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<8) { i in
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hue: Double(i) / 8, saturation: 0.55, brightness: 0.88))
                                .frame(width: 180, height: 90)
                                .overlay(Text("Snap \(i + 1)").font(.subheadline).bold())
                                .scrollTransition { content, phase in
                                    content.opacity(phase.isIdentity ? 1 : 0.6)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.94)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                .scrollTargetBehavior(.viewAligned)

                Text(".scrollTargetBehavior(.viewAligned) + .scrollTargetLayout()")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // 4. Horizontal — edge fade
            Section("Horizontal — edge fade") {
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<10) { i in
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hue: Double(i) / 10, saturation: 0.4, brightness: 0.9))
                                    .frame(width: 110, height: 76)
                                    .overlay(Text("Card \(i + 1)").font(.caption))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                    }
                    // Leading fade
                    HStack {
                        LinearGradient(
                            colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 28)
                        Spacer()
                        // Trailing fade
                        LinearGradient(
                            colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 28)
                    }
                    .allowsHitTesting(false)
                }

                Text("LinearGradient overlay on leading + trailing edges")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // 5. Carousel & pagination
            Section("Carousel & pagination") {
                TabView {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hue: Double(i) / 5, saturation: 0.6, brightness: 0.85))
                            .overlay(
                                Text("Page \(i + 1)")
                                    .font(.title3).bold()
                            )
                            .padding(.horizontal, 8)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 180)

                Text(".tabViewStyle(.page(indexDisplayMode: .always))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Scroll Views")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - GroupedFormsView (unchanged)

struct GroupedFormsView: View {
    @State private var name = ""
    @State private var notifications = true
    @State private var theme = "System"

    var body: some View {
        Form {
            Section("Account") {
                TextField("Full name", text: $name)
                HStack {
                    Text("Email")
                    Spacer()
                    Text("matt@example.com").foregroundStyle(.secondary)
                }
            }
            Section("Preferences") {
                Toggle("Push Notifications", isOn: $notifications)
                Picker("Appearance", selection: $theme) {
                    ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) }
                }
                NavigationLink("Privacy") { Text("Privacy settings") }
            }
            Section {
                Button("Sign Out", role: .destructive) {}
            }
        }
        .navigationTitle("Forms")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - CardsView (#013 — interactive demos appended)

struct CardsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Existing static examples
                CardExample(
                    title: "Basic Card",
                    description: "A simple rounded rectangle with shadow"
                )
                CardExample(
                    title: "Card with Fill",
                    description: "Secondary background fill, no shadow"
                )
                .background(Color(.secondarySystemBackground))
                HStack(spacing: 12) {
                    ForEach(["Card A", "Card B"], id: \.self) { title in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 120)
                            .overlay(Text(title).font(.headline))
                            .frame(maxWidth: .infinity)
                    }
                }

                Divider()

                // 1. Expandable card
                ExpandableCard()

                // 2. Long press to peek
                LongPressPeekCard()

                // 3. Swipeable card
                SwipeableCard()

                // 4. Glass card
                GlassCard()
            }
            .padding()
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: Expandable Card

private struct ExpandableCard: View {
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expandable card")
                        .font(.headline)
                    Text("withAnimation(.spring()) · @State var expanded")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .animation(.spring(), value: expanded)
            }
            .padding(16)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("This body text is revealed on tap. The layout change is driven by an @State Bool toggled inside withAnimation(.spring()), giving the expand/collapse a natural feel without manual spring math.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.secondarySystemBackground),
                     in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            withAnimation(.spring()) { expanded.toggle() }
        }
    }
}

// MARK: Long Press to Peek Card

private struct LongPressPeekCard: View {
    @GestureState private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Long press to peek")
                        .font(.headline)
                    Text("@GestureState · .onLongPressGesture · scaleEffect")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "hand.point.up.left")
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            if isPressed {
                Divider()
                HStack(spacing: 16) {
                    Button {} label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                    }
                    Button {} label: {
                        Label("Save", systemImage: "bookmark")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.secondarySystemBackground),
                     in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .gesture(
            LongPressGesture(minimumDuration: 0.4)
                .updating($isPressed) { value, state, _ in state = value }
        )
    }
}

// MARK: Swipeable Card

private struct SwipeableCard: View {
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Hint layer behind the card
            HStack {
                Spacer()
                Label("Dismiss", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline)
                    .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color(.secondarySystemBackground),
                         in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Swipeable card")
                    .font(.headline)
                Text("DragGesture · offset · rotationEffect")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Drag me — snaps back if < 100 pt")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground),
                         in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .offset(x: dragOffset)
            .rotationEffect(.degrees(Double(dragOffset) / 20))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            // Snap back — threshold is 100 pt
                            dragOffset = 0
                        }
                    }
            )
        }
    }
}

// MARK: Glass Card

private struct GlassCard: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: animateGradient
                    ? [Color.purple, Color.blue, Color.teal]
                    : [Color.orange, Color.pink, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            VStack(alignment: .leading, spacing: 6) {
                Text("Glass card")
                    .font(.headline)
                Text(".ultraThinMaterial · animated LinearGradient")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("The gradient shifts endlessly behind the material blur layer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(height: 120)
        .onAppear { animateGradient = true }
    }
}

// MARK: - CardExample (unchanged)

struct CardExample: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(description).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ListsView()
    }
}
