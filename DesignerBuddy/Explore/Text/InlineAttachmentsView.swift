import SwiftUI
import UIKit

// MARK: - Inline Text Attachments
//
// TextKit 2's NSTextAttachmentViewProvider puts real, live UIViews inline
// with flowing text — chips, badges, and indicators that wrap and reflow
// like glyphs. Before iOS 15, attachments were static images only.

struct InlineAttachmentsView: View {
    @State private var largeChips = false
    @State private var animateDot = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                previewCard
                controlsCard
                pipelineCard
            }
            .padding(16)
        }
        .navigationTitle("Inline Text Attachments")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Chips in Text", systemImage: "puzzlepiece.extension").font(.headline)
                Spacer()
                Text("TextKit 2")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }

            AttachmentTextView(large: largeChips, animateDot: animateDot)
                .frame(height: 250)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Text("The chips are UIViews, not images — the status dot is running a CoreAnimation loop while the text around it wraps normally.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Controls Card

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Controls", systemImage: "slider.horizontal.3").font(.headline)

            Toggle(isOn: $largeChips) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Large chips").font(.subheadline)
                    Text("attachmentBounds(for:) re-answers sizing and every line reflows")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $animateDot) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Pulse status dot").font(.subheadline)
                    Text("Proof the attachment view is alive, not rasterized")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Pipeline Card

    private var pipelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("The Pipeline", systemImage: "arrow.trianglehead.2.clockwise.rotate.90").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                apiRow("NSTextAttachment", "Subclassed to carry the chip's title, tint, and icon in the attributed string")
                apiRow("viewProvider(for:location:textContainer:)", "The attachment vends a provider instead of an image")
                apiRow("NSTextAttachmentViewProvider", "loadView() builds the UIView; tracksTextAttachmentViewBounds opts into custom sizing")
                apiRow("attachmentBounds(for:...)", "Returns the rect the layout manager reserves in the line fragment")
            }

            Text("SwiftUI's Text can interleave images via Text(Image:), but live inline views in wrapping text are still a TextKit-only trick.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func apiRow(_ api: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(api).font(.caption.monospaced()).foregroundStyle(.blue)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Text view host

private struct AttachmentTextView: UIViewRepresentable {
    var large: Bool
    var animateDot: Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = Self.buildText(large: large, animateDot: animateDot)
    }

    private static func buildText(large: Bool, animateDot: Bool) -> NSAttributedString {
        let bodySize: CGFloat = large ? 19 : 16
        let chipSize: CGFloat = large ? 16 : 13

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 7
        paragraph.paragraphSpacing = 12
        let base: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: bodySize),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph,
        ]

        func chip(_ title: String, icon: String?, tint: UIColor, pulses: Bool = false) -> NSAttributedString {
            let attachment = ChipAttachment(title: title, icon: icon, tint: tint,
                                            pulses: pulses, pointSize: chipSize)
            let string = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            // The attachment run needs the base attributes too, so the line
            // fragment reserves a consistent height around the view.
            string.addAttributes(base, range: NSRange(location: 0, length: string.length))
            return string
        }

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "Handoff notes — ", attributes: base))
        result.append(chip("Riley Chen", icon: "person.crop.circle.fill", tint: .systemIndigo))
        result.append(NSAttributedString(string: " finished the exploration and moved it to ", attributes: base))
        result.append(chip("In Review", icon: nil, tint: .systemGreen, pulses: animateDot))
        result.append(NSAttributedString(string: ".\nTokens ship with ", attributes: base))
        result.append(chip("DS-482", icon: "tag.fill", tint: .systemBlue))
        result.append(NSAttributedString(string: " and the crit is booked for ", attributes: base))
        result.append(chip("Tue 10:30", icon: "calendar", tint: .systemOrange))
        result.append(NSAttributedString(string: ". Ping ", attributes: base))
        result.append(chip("Sam Ortiz", icon: "person.crop.circle.fill", tint: .systemPink))
        result.append(NSAttributedString(string: " if the contrast checks slip.", attributes: base))
        return result
    }
}

// MARK: - Attachment + view provider

private final class ChipAttachment: NSTextAttachment {
    let title: String
    let icon: String?
    let tint: UIColor
    let pulses: Bool
    let pointSize: CGFloat

    init(title: String, icon: String?, tint: UIColor, pulses: Bool, pointSize: CGFloat) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.pulses = pulses
        self.pointSize = pointSize
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var chipSize: CGSize {
        ChipUIView.size(title: title, hasIcon: icon != nil, hasDot: pulses, pointSize: pointSize)
    }

    override func viewProvider(for parentView: UIView?,
                               location: any NSTextLocation,
                               textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        let provider = ChipViewProvider(textAttachment: self,
                                        parentView: parentView,
                                        textLayoutManager: textContainer?.textLayoutManager,
                                        location: location)
        provider.tracksTextAttachmentViewBounds = true
        return provider
    }
}

private final class ChipViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        guard let chip = textAttachment as? ChipAttachment else {
            view = UIView()
            return
        }
        view = ChipUIView(title: chip.title, icon: chip.icon, tint: chip.tint,
                          pulses: chip.pulses, pointSize: chip.pointSize)
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                   location: any NSTextLocation,
                                   textContainer: NSTextContainer?,
                                   proposedLineFragment: CGRect,
                                   position: CGPoint) -> CGRect {
        guard let chip = textAttachment as? ChipAttachment else { return .zero }
        let size = chip.chipSize
        let capHeight = (attributes[.font] as? UIFont)?.capHeight ?? 12
        // Center the chip on the cap height so it sits optically mid-line.
        return CGRect(x: 0, y: (capHeight - size.height) / 2, width: size.width, height: size.height)
    }
}

// MARK: - Chip view

private final class ChipUIView: UIView {
    private let label = UILabel()
    private let iconView = UIImageView()
    private let dot = UIView()
    private let pulses: Bool
    private let hasIcon: Bool

    init(title: String, icon: String?, tint: UIColor, pulses: Bool, pointSize: CGFloat) {
        self.pulses = pulses
        self.hasIcon = icon != nil
        let size = Self.size(title: title, hasIcon: icon != nil, hasDot: pulses, pointSize: pointSize)
        super.init(frame: CGRect(origin: .zero, size: size))

        backgroundColor = tint.withAlphaComponent(0.14)
        layer.cornerRadius = size.height / 2
        layer.masksToBounds = true

        label.text = title
        label.font = Self.font(pointSize: pointSize)
        label.textColor = tint
        addSubview(label)

        if let icon {
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize * 0.85, weight: .medium)
            iconView.image = UIImage(systemName: icon, withConfiguration: configuration)
            iconView.tintColor = tint
            iconView.contentMode = .scaleAspectFit
            addSubview(iconView)
        }

        if pulses {
            dot.backgroundColor = tint
            addSubview(dot)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = Self.horizontalInset
        var x = inset
        if pulses {
            let dotSize: CGFloat = 7
            dot.frame = CGRect(x: x, y: (bounds.height - dotSize) / 2, width: dotSize, height: dotSize)
            dot.layer.cornerRadius = dotSize / 2
            x += dotSize + Self.elementGap
        } else if hasIcon {
            let iconSide = bounds.height * 0.6
            iconView.frame = CGRect(x: x, y: (bounds.height - iconSide) / 2, width: iconSide, height: iconSide)
            x += iconSide + Self.elementGap
        }
        label.frame = CGRect(x: x, y: 0, width: bounds.width - x - inset, height: bounds.height)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard pulses, window != nil else { return }
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.25
        pulse.duration = 0.7
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        dot.layer.add(pulse, forKey: "pulse")
    }

    private static let horizontalInset: CGFloat = 9
    private static let elementGap: CGFloat = 4

    static func font(pointSize: CGFloat) -> UIFont {
        .systemFont(ofSize: pointSize, weight: .medium)
    }

    static func size(title: String, hasIcon: Bool, hasDot: Bool, pointSize: CGFloat) -> CGSize {
        let font = font(pointSize: pointSize)
        let textWidth = (title as NSString).size(withAttributes: [.font: font]).width
        let height = ceil(font.lineHeight) + 8
        var width = textWidth + horizontalInset * 2
        if hasDot {
            width += 7 + elementGap
        } else if hasIcon {
            width += height * 0.6 + elementGap
        }
        return CGSize(width: ceil(width), height: height)
    }
}

#Preview {
    NavigationStack { InlineAttachmentsView() }
}
