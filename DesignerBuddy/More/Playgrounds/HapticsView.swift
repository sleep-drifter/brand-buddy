import SwiftUI
import UIKit

struct HapticsView: View {
    var body: some View {
        List {
            Section("Impact Feedback") {
                ForEach(ImpactItem.all) { item in
                    HapticButton(label: item.name, subtitle: item.description) {
                        let g = UIImpactFeedbackGenerator(style: item.style)
                        g.prepare()
                        g.impactOccurred()
                    }
                }
            }

            Section("Notification Feedback") {
                ForEach(NotificationItem.all) { item in
                    HapticButton(label: item.name, subtitle: item.description) {
                        let g = UINotificationFeedbackGenerator()
                        g.prepare()
                        g.notificationOccurred(item.type)
                    }
                }
            }

            Section("Selection Feedback") {
                HapticButton(
                    label: "Selection Changed",
                    subtitle: "Light tick — use when moving through a picker or list selection."
                ) {
                    let g = UISelectionFeedbackGenerator()
                    g.prepare()
                    g.selectionChanged()
                }
            }

            Section("Usage Guidelines") {
                ForEach(HapticGuideline.all) { guide in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: guide.icon)
                                .foregroundStyle(guide.positive ? .green : .red)
                                .font(.caption)
                                .frame(width: 16)
                            Text(guide.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(guide.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 22)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Haptics")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HapticButton: View {
    let label: String
    let subtitle: String
    let action: () -> Void

    @State private var fired = false

    var body: some View {
        Button {
            action()
            withAnimation(.spring(duration: 0.12)) { fired = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(duration: 0.3)) { fired = false }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(fired ? .tint : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(fired ? .tint.opacity(0.7) : .secondary)
                }
                Spacer()
                Image(systemName: fired ? "hand.tap.fill" : "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .scaleEffect(fired ? 1.2 : 1.0)
            }
        }
        .scaleEffect(fired ? 0.95 : 1.0)
        .padding(.vertical, 2)
    }
}

struct ImpactItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    static let all: [ImpactItem] = [
        ImpactItem(name: "Light",  description: "Subtle acknowledgment, minor actions.",      style: .light),
        ImpactItem(name: "Medium", description: "Standard interaction feedback.",              style: .medium),
        ImpactItem(name: "Heavy",  description: "Significant action, drag completion.",        style: .heavy),
        ImpactItem(name: "Soft",   description: "Softer than light, elastic feel.",            style: .soft),
        ImpactItem(name: "Rigid",  description: "Hard stop, hitting a boundary.",              style: .rigid),
    ]
}

struct NotificationItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let type: UINotificationFeedbackGenerator.FeedbackType

    static let all: [NotificationItem] = [
        NotificationItem(name: "Success", description: "Task completed — payment, upload, send.",          type: .success),
        NotificationItem(name: "Warning", description: "Needs attention — low battery, caution.",          type: .warning),
        NotificationItem(name: "Error",   description: "Something failed — wrong password, invalid input.", type: .error),
    ]
}

struct HapticGuideline: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let positive: Bool

    static let all: [HapticGuideline] = [
        HapticGuideline(title: "Match haptic weight to action weight",       detail: "Light tap → light impact. Destructive action → heavy or notification.",  icon: "checkmark.circle", positive: true),
        HapticGuideline(title: "Pair with visual feedback",                  detail: "Haptics reinforce visual changes; they don't replace them.",               icon: "checkmark.circle", positive: true),
        HapticGuideline(title: "Respect reduced motion & haptics settings",  detail: "Check UIAccessibility.isReduceMotionEnabled. Many users disable haptics.", icon: "checkmark.circle", positive: true),
        HapticGuideline(title: "Don't use haptics as decoration",            detail: "Overuse desensitizes users and drains battery. Only on meaningful events.", icon: "xmark.circle",     positive: false),
        HapticGuideline(title: "Don't fire on every frame or scroll tick",   detail: "Selection feedback is for discrete item selection, not continuous scrolling.", icon: "xmark.circle", positive: false),
    ]
}

#Preview {
    NavigationStack {
        HapticsView()
    }
}
