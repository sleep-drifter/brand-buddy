import SwiftUI

struct SwipeableRowsView: View {
    var body: some View {
        List {
            trailingActionsSection
            leadingActionsSection
            destructiveSection
            fullSwipeSection
            multipleActionsSection
            tintedActionsSection
        }
        .navigationTitle("Swipeable Rows")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sections

    private var trailingActionsSection: some View {
        Section {
            ForEach(EmailItem.samples) { item in
                TrailingSwipeRow(item: item)
            }
        } header: {
            Text("Trailing actions")
        } footer: {
            Text("Swipe left to reveal actions. The rightmost action is the default full-swipe action.")
        }
    }

    private var leadingActionsSection: some View {
        Section {
            ForEach(EmailItem.samples) { item in
                LeadingSwipeRow(item: item)
            }
        } header: {
            Text("Leading actions")
        } footer: {
            Text("Swipe right to reveal leading actions. Common for quick-flag or archive gestures.")
        }
    }

    private var destructiveSection: some View {
        Section {
            DestructiveSwipeDemo()
        } header: {
            Text("Destructive action")
        } footer: {
            Text("Use `.destructive` role for irreversible actions. The row is removed automatically on full-swipe.")
        }
    }

    private var fullSwipeSection: some View {
        Section {
            FullSwipeDemo()
        } header: {
            Text("Disable full-swipe")
        } footer: {
            Text("Set `allowsFullSwipe: false` when the action is consequential enough to require an explicit tap.")
        }
    }

    private var multipleActionsSection: some View {
        Section {
            ForEach(FileItem.samples) { item in
                MultiActionRow(item: item)
            }
        } header: {
            Text("Multiple actions")
        } footer: {
            Text("Up to three actions per edge. Displayed right-to-left for trailing, left-to-right for leading.")
        }
    }

    private var tintedActionsSection: some View {
        Section {
            ForEach(ContactItem.samples) { item in
                TintedActionRow(item: item)
            }
        } header: {
            Text("Tinted actions")
        } footer: {
            Text("Custom `.tint()` gives each action a distinct color while keeping the system button shape.")
        }
    }
}

// MARK: - Models

private struct EmailItem: Identifiable {
    let id = UUID()
    let sender: String
    let subject: String
    var isUnread: Bool = true
    var isFlagged: Bool = false

    static let samples = [
        EmailItem(sender: "Alex Kim",     subject: "Design review tomorrow", isUnread: true),
        EmailItem(sender: "Sam Rivera",   subject: "Q2 roadmap feedback",    isUnread: true),
        EmailItem(sender: "Jordan Lee",   subject: "Lunch on Friday?",        isUnread: false, isFlagged: true),
    ]
}

private struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color

    static let samples = [
        FileItem(name: "Pitch Deck.key",      icon: "keynote",         color: .blue),
        FileItem(name: "Budget 2026.numbers", icon: "tablecells",      color: .green),
        FileItem(name: "Brief.pages",         icon: "doc.text",        color: .orange),
    ]
}

private struct ContactItem: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let color: Color

    static let samples = [
        ContactItem(name: "Priya Nair",    initials: "PN", color: .indigo),
        ContactItem(name: "Carlos Vega",   initials: "CV", color: .teal),
        ContactItem(name: "Mia Thornton", initials: "MT", color: .pink),
    ]
}

// MARK: - Row Views

private struct TrailingSwipeRow: View {
    let item: EmailItem
    @State private var isUnread: Bool
    @State private var isFlagged: Bool

    init(item: EmailItem) {
        self.item = item
        _isUnread = State(initialValue: item.isUnread)
        _isFlagged = State(initialValue: item.isFlagged)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isUnread ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.sender)
                    .fontWeight(isUnread ? .semibold : .regular)
                Text(item.subject)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {} label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                isFlagged.toggle()
            } label: {
                Label(isFlagged ? "Unflag" : "Flag", systemImage: isFlagged ? "flag.slash" : "flag")
            }
            .tint(.orange)
        }
    }
}

private struct LeadingSwipeRow: View {
    let item: EmailItem
    @State private var isUnread: Bool

    init(item: EmailItem) {
        self.item = item
        _isUnread = State(initialValue: item.isUnread)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isUnread ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.sender)
                    .fontWeight(isUnread ? .semibold : .regular)
                Text(item.subject)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                isUnread.toggle()
            } label: {
                Label(isUnread ? "Read" : "Unread", systemImage: isUnread ? "envelope.open" : "envelope.badge")
            }
            .tint(isUnread ? .gray : .accentColor)
        }
    }
}

private struct DestructiveSwipeDemo: View {
    @State private var items = ["Vacation photos", "Old receipts", "Draft notes", "Temp files"]

    var body: some View {
        ForEach(items, id: \.self) { item in
            Label(item, systemImage: "doc")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        items.removeAll { $0 == item }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}

private struct FullSwipeDemo: View {
    @State private var isArchived = false

    var body: some View {
        Label("Important contract.pdf", systemImage: "doc.badge.ellipsis")
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {} label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    isArchived.toggle()
                } label: {
                    Label(isArchived ? "Unarchive" : "Archive", systemImage: isArchived ? "tray.and.arrow.up" : "archivebox")
                }
                .tint(.gray)
            }
    }
}

private struct MultiActionRow: View {
    let item: FileItem

    var body: some View {
        Label(item.name, systemImage: item.icon)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {} label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {} label: {
                    Label("Move", systemImage: "folder")
                }
                .tint(.indigo)
                Button {} label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.blue)
            }
            .swipeActions(edge: .leading) {
                Button {} label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                .tint(.teal)
            }
    }
}

private struct TintedActionRow: View {
    let item: ContactItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(item.color.gradient)
                Text(item.initials)
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)
            Text(item.name)
        }
        .swipeActions(edge: .trailing) {
            Button {} label: {
                Label("Message", systemImage: "bubble")
            }
            .tint(.green)
            Button {} label: {
                Label("Call", systemImage: "phone")
            }
            .tint(.blue)
            Button {} label: {
                Label("Video", systemImage: "video")
            }
            .tint(.purple)
        }
        .swipeActions(edge: .leading) {
            Button {} label: {
                Label("Favorite", systemImage: "star")
            }
            .tint(.yellow)
        }
    }
}

#Preview {
    NavigationStack {
        SwipeableRowsView()
    }
}
