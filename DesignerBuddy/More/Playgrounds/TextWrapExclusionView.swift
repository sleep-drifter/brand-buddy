import SwiftUI
import UIKit

// MARK: - Text Wrap & Exclusion
//
// NSTextContainer.exclusionPaths carves regions out of the text container
// so lines flow around them — the magazine-style text wrap CSS calls
// "shape-outside". Drag the shape and TextKit relays out live.

struct TextWrapExclusionView: View {
    private enum WrapShape: String, CaseIterable, Identifiable {
        case circle = "Circle"
        case square = "Square"
        case capsule = "Capsule"
        var id: Self { self }
    }

    @State private var shape: WrapShape = .circle
    @State private var size: CGFloat = 120
    @State private var center = CGPoint(x: 170, y: 150)
    @State private var showOutline = true
    @State private var canvasSize = CGSize(width: 340, height: 340)

    /// Breathing room between the visible shape and the text edge.
    private let margin: CGFloat = 10

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                canvasCard
                controlsCard
                notesCard
            }
            .padding(16)
        }
        .navigationTitle("Text Wrap & Exclusion")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Canvas Card

    private var canvasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Drag the Shape", systemImage: "text.below.photo").font(.headline)
                Spacer()
                Text("exclusionPaths")
                    .font(.mono(.caption2))
                    .foregroundStyle(.secondary)
            }

            ZStack {
                ExclusionTextView(text: Self.sample, exclusionPaths: [exclusionPath])
                shapeView
                    .position(center)
                if showOutline {
                    outlineView
                        .position(center)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .coordinateSpace(name: "wrapCanvas")
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                canvasSize = newSize
                center = clamp(center)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var shapeRect: CGRect {
        let width: CGFloat = shape == .capsule ? size * 1.5 : size
        let height: CGFloat = shape == .capsule ? size * 0.6 : size
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    private var exclusionPath: UIBezierPath {
        let rect = shapeRect.insetBy(dx: -margin, dy: -margin)
        switch shape {
        case .circle:  return UIBezierPath(ovalIn: rect)
        case .square:  return UIBezierPath(roundedRect: rect, cornerRadius: 26)
        case .capsule: return UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        }
    }

    private var shapeView: some View {
        wrapShape
            .fill(Color.blue.opacity(0.16))
            .overlay {
                wrapShape.stroke(Color.blue.opacity(0.7), lineWidth: 1.5)
            }
            .overlay {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue.opacity(0.8))
            }
            .frame(width: shapeRect.width, height: shapeRect.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("wrapCanvas"))
                    .onChanged { value in
                        center = clamp(value.location)
                    }
            )
            .animation(.spring(response: 0.25), value: shape)
    }

    private var outlineView: some View {
        let rect = shapeRect.insetBy(dx: -margin, dy: -margin)
        return wrapShape
            .stroke(Color.blue.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(width: rect.width, height: rect.height)
    }

    private var wrapShape: AnyShape {
        switch shape {
        case .circle:  AnyShape(Ellipse())
        case .square:  AnyShape(RoundedRectangle(cornerRadius: 22))
        case .capsule: AnyShape(Capsule())
        }
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        let halfWidth = shapeRect.width / 2
        let halfHeight = shapeRect.height / 2
        guard canvasSize.width > 0, canvasSize.height > 0 else { return point }
        return CGPoint(
            x: min(max(point.x, halfWidth * 0.4), canvasSize.width - halfWidth * 0.4),
            y: min(max(point.y, halfHeight * 0.4), canvasSize.height - halfHeight * 0.4)
        )
    }

    // MARK: Controls Card

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Shape", systemImage: "slider.horizontal.3").font(.headline)

            Picker("Shape", selection: $shape) {
                ForEach(WrapShape.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Size").font(.subheadline)
                    Spacer()
                    Text("\(Int(size)) pt").font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                Slider(value: $size, in: 70...180, step: 1) { _ in
                    center = clamp(center)
                }
            }

            Toggle(isOn: $showOutline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Show exclusion path").font(.subheadline)
                    Text("The dashed line is what TextKit actually avoids — shape plus margin")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Button("Reset position") {
                withAnimation(.spring(response: 0.35)) {
                    center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                }
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "list.bullet.rectangle").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                noteRow("Coordinates", "Exclusion paths live in text-container space. With textContainerInset zero and lineFragmentPadding zero, that space equals the view's bounds — so the SwiftUI drag location maps 1:1.")
                noteRow("Margins", "Wrap the visible shape in an inset path; text hugging the exact edge reads as a collision, not a wrap.")
                noteRow("Slivers", "When the shape sits near an edge, TextKit drops line fragments that would be too narrow — words never squeeze into slivers.")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func noteRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).fontWeight(.medium)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }

    private static let sample: String = {
        let paragraph = "Layout is negotiation. Every line fragment asks the text container how much width it may have, and the container answers after subtracting whatever the exclusion paths claim. Move the shape and the negotiation reruns — lines shorten, break early, or step aside entirely. "
        return paragraph + paragraph + paragraph
    }()
}

// MARK: - UITextView host

private struct ExclusionTextView: UIViewRepresentable {
    let text: String
    let exclusionPaths: [UIBezierPath]

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .footnote)
        textView.textColor = .secondaryLabel
        textView.text = text
        textView.clipsToBounds = true
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.textContainer.exclusionPaths = exclusionPaths
    }
}

#Preview {
    NavigationStack { TextWrapExclusionView() }
}
