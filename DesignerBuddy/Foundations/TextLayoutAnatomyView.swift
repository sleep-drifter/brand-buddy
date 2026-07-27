import SwiftUI
import UIKit

// MARK: - Text Layout Anatomy
//
// Visualizes how TextKit 2 (NSTextLayoutManager) breaks a document into
// layout fragments and line fragments, and where the font's vertical
// metrics sit on each line. The text itself is drawn by TextKit into the
// same Canvas the overlays use, so every guide lines up exactly.

struct TextLayoutAnatomyView: View {
    @State private var fontChoice: AnatomyFontChoice = .system
    @State private var fontSize: CGFloat = 24
    @State private var lineSpacing: CGFloat = 6
    @State private var sample: AnatomySample = .paragraphs

    @State private var showFragments = true
    @State private var showLineBoxes = true
    @State private var showBaselines = true
    @State private var showFontMetrics = false

    @State private var canvasWidth: CGFloat = 320
    @Environment(\.colorScheme) private var colorScheme

    private var font: UIFont { fontChoice.uiFont(size: fontSize) }

    /// UIKit dynamic colors don't reliably resolve against the SwiftUI
    /// trait environment inside a Canvas, so resolve .label explicitly.
    private var resolvedTextColor: UIColor {
        UIColor.label.resolvedColor(with: UITraitCollection(
            userInterfaceStyle: colorScheme == .dark ? .dark : .light
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                canvasCard
                layersCard
                controlsCard
                metricsCard
                glossaryCard
            }
            .padding(16)
        }
        .navigationTitle("Text Layout Anatomy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Canvas Card

    private var canvasCard: some View {
        let engine = AnatomyEngine(text: sample.text, font: font, lineSpacing: lineSpacing,
                                   width: canvasWidth, textColor: resolvedTextColor)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Layout", systemImage: "text.line.first.and.arrowtriangle.forward").font(.headline)
                Spacer()
                Text("\(engine.snapshot.fragments.count) fragments · \(engine.snapshot.lines.count) lines")
                    .font(.mono(.caption2))
                    .foregroundStyle(.secondary)
            }

            Canvas { context, _ in
                drawOverlaysBehindText(engine: engine, in: &context)
                context.withCGContext { cg in
                    engine.drawText(in: cg)
                }
                drawOverlaysAboveText(engine: engine, in: &context)
            }
            .frame(height: max(engine.snapshot.height + 8, 60))
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                if width > 0 { canvasWidth = width }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func drawOverlaysBehindText(engine: AnatomyEngine, in context: inout GraphicsContext) {
        if showFragments {
            for frame in engine.snapshot.fragments {
                let path = Path(roundedRect: frame.insetBy(dx: -3, dy: 0), cornerRadius: 4)
                context.fill(path, with: .color(.blue.opacity(0.06)))
                context.stroke(path, with: .color(.blue.opacity(0.7)), style: StrokeStyle(lineWidth: 1))
            }
        }
        if showLineBoxes {
            for line in engine.snapshot.lines {
                let path = Path(line.typographicBounds)
                context.fill(path, with: .color(.teal.opacity(0.12)))
                context.stroke(path, with: .color(.teal.opacity(0.6)), style: StrokeStyle(lineWidth: 0.5))
            }
        }
    }

    private func drawOverlaysAboveText(engine: AnatomyEngine, in context: inout GraphicsContext) {
        for line in engine.snapshot.lines {
            let bounds = line.typographicBounds
            let baselineY = line.baseline.y

            if showFontMetrics {
                drawGuide(in: &context, y: baselineY - font.ascender, over: bounds, color: .green, dashed: true)
                drawGuide(in: &context, y: baselineY - font.capHeight, over: bounds, color: .orange, dashed: true)
                drawGuide(in: &context, y: baselineY - font.xHeight, over: bounds, color: .purple, dashed: true)
                drawGuide(in: &context, y: baselineY - font.descender, over: bounds, color: .pink, dashed: true)
            }
            if showBaselines {
                drawGuide(in: &context, y: baselineY, over: bounds, color: .red, dashed: false)
            }
        }
    }

    private func drawGuide(in context: inout GraphicsContext, y: CGFloat, over bounds: CGRect, color: Color, dashed: Bool) {
        var path = Path()
        path.move(to: CGPoint(x: bounds.minX - 2, y: y))
        path.addLine(to: CGPoint(x: bounds.maxX + 2, y: y))
        let style = dashed
            ? StrokeStyle(lineWidth: 1, dash: [3, 2])
            : StrokeStyle(lineWidth: 1)
        context.stroke(path, with: .color(color.opacity(0.85)), style: style)
    }

    // MARK: Layers Card

    private var layersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Layers", systemImage: "square.3.layers.3d").font(.headline)

            Toggle(isOn: $showFragments)   { legendRow(color: .blue,   title: "Layout fragments",  detail: "One per paragraph — NSTextLayoutFragment") }
            Toggle(isOn: $showLineBoxes)   { legendRow(color: .teal,   title: "Line fragments",    detail: "Typographic bounds — NSTextLineFragment") }
            Toggle(isOn: $showBaselines)   { legendRow(color: .red,    title: "Baselines",         detail: "Where glyphs sit — from glyphOrigin") }
            Toggle(isOn: $showFontMetrics) { legendRow(color: .orange, title: "Font metrics",      detail: "Ascender, cap height, x-height, descender") }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func legendRow(color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Controls Card

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Type Controls", systemImage: "slider.horizontal.3").font(.headline)

            Picker("Font", selection: $fontChoice) {
                ForEach(AnatomyFontChoice.allCases) { choice in
                    Text(choice.rawValue).tag(choice)
                }
            }
            .pickerStyle(.segmented)

            Picker("Sample", selection: $sample) {
                ForEach(AnatomySample.allCases) { sample in
                    Text(sample.rawValue).tag(sample)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Size").font(.subheadline)
                    Spacer()
                    Text("\(Int(fontSize)) pt").font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                Slider(value: $fontSize, in: 14...40, step: 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Line spacing").font(.subheadline)
                    Spacer()
                    Text("\(Int(lineSpacing)) pt").font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                Slider(value: $lineSpacing, in: 0...24, step: 1)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Metrics Card

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Font Metrics", systemImage: "ruler").font(.headline)

            VStack(spacing: 8) {
                metricRow("pointSize",  font.pointSize,  "Requested size — not the visual height")
                Divider()
                metricRow("ascender",   font.ascender,   "Baseline to top of tallest glyphs")
                Divider()
                metricRow("capHeight",  font.capHeight,  "Baseline to top of flat capitals like H")
                Divider()
                metricRow("xHeight",    font.xHeight,    "Baseline to top of lowercase x")
                Divider()
                metricRow("descender",  font.descender,  "Baseline to bottom of glyphs (negative)")
                Divider()
                metricRow("lineHeight", font.lineHeight, "Default line box: ascender − descender")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func metricRow(_ name: String, _ value: CGFloat, _ detail: String) -> some View {
        HStack(alignment: .top) {
            Text(name)
                .font(.caption.monospaced())
                .foregroundStyle(.blue)
                .frame(width: 88, alignment: .leading)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.1f", value))
                .font(.mono(.caption2))
        }
    }

    // MARK: Glossary Card

    private var glossaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How TextKit 2 Sees Text", systemImage: "character.book.closed").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                glossaryRow("NSTextLayoutManager", "Owns layout. Replaces TextKit 1's glyph-based NSLayoutManager with paragraph-level, value-type layout.")
                glossaryRow("NSTextLayoutFragment", "The layout result for one unit of text — typically a paragraph. What you'd animate or redraw independently.")
                glossaryRow("NSTextLineFragment", "One rendered line inside a fragment, with typographic bounds and a glyph origin (the baseline).")
            }

            Text("Line spacing stretches the gap between line fragments; the font's own metrics never change. That's why baselines, not box edges, are the reference for aligning text to other elements.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func glossaryRow(_ term: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(term).font(.caption.monospaced()).foregroundStyle(.blue)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Font & Sample Options

private enum AnatomyFontChoice: String, CaseIterable, Identifiable {
    case system = "System"
    case serif = "Serif"
    case rounded = "Rounded"
    case mono = "Mono"

    var id: Self { self }

    func uiFont(size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size)
        let design: UIFontDescriptor.SystemDesign
        switch self {
        case .system:  return base
        case .serif:   design = .serif
        case .rounded: design = .rounded
        case .mono:    design = .monospaced
        }
        guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

private enum AnatomySample: String, CaseIterable, Identifiable {
    case specimen = "Specimen"
    case paragraphs = "Paragraphs"
    case mixed = "Mixed"

    var id: Self { self }

    var text: String {
        switch self {
        case .specimen:
            return "Hamburgevons Quickly Jig"
        case .paragraphs:
            return "Typography gives language a durable visual form.\nEach paragraph becomes its own layout fragment, and each wrapped line becomes a line fragment inside it."
        case .mixed:
            return "Ascenders fly high 🚀 while descenders dig deep — jumpy glyphs push past x-height."
        }
    }
}

// MARK: - Layout Engine

private struct AnatomyLine {
    let typographicBounds: CGRect
    let baseline: CGPoint
}

private struct AnatomySnapshot {
    var fragments: [CGRect] = []
    var lines: [AnatomyLine] = []
    var height: CGFloat = 0
}

/// Builds a standalone TextKit 2 stack (no UITextView needed) and captures
/// fragment geometry. Kept alive as one value so the layout manager the
/// snapshot came from is also the one that draws.
private struct AnatomyEngine {
    let contentStorage: NSTextContentStorage
    let layoutManager: NSTextLayoutManager
    let snapshot: AnatomySnapshot

    init(text: String, font: UIFont, lineSpacing: CGFloat, width: CGFloat, textColor: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph,
        ])

        let contentStorage = NSTextContentStorage()
        let layoutManager = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(layoutManager)

        let container = NSTextContainer(size: CGSize(width: max(width, 10), height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        layoutManager.textContainer = container
        contentStorage.textStorage?.setAttributedString(attributed)

        var snapshot = AnatomySnapshot()
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location,
                                                   options: [.ensuresLayout]) { fragment in
            let frame = fragment.layoutFragmentFrame
            snapshot.fragments.append(frame)
            for line in fragment.textLineFragments {
                let bounds = line.typographicBounds.offsetBy(dx: frame.minX, dy: frame.minY)
                let baseline = CGPoint(x: bounds.minX + line.glyphOrigin.x,
                                       y: bounds.minY + line.glyphOrigin.y)
                snapshot.lines.append(AnatomyLine(typographicBounds: bounds, baseline: baseline))
            }
            snapshot.height = max(snapshot.height, frame.maxY)
            return true
        }

        self.contentStorage = contentStorage
        self.layoutManager = layoutManager
        self.snapshot = snapshot
    }

    func drawText(in context: CGContext) {
        // UIGraphicsPushContext makes UIKit-flavored text drawing valid in
        // the Canvas's CGContext.
        UIGraphicsPushContext(context)
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location,
                                                   options: [.ensuresLayout]) { fragment in
            fragment.draw(at: fragment.layoutFragmentFrame.origin, in: context)
            return true
        }
        UIGraphicsPopContext()
    }
}

#Preview {
    NavigationStack { TextLayoutAnatomyView() }
}
