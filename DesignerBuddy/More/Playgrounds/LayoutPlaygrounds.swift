import PhotosUI
import SwiftUI
import UIKit

// Custom-Layout playgrounds ported from Koshimizu-Takehito's my-toybox
// (RadialLayout / FlowLayout). Pure SwiftUI Layout protocol — no Metal.

// MARK: - Radial ring layout

/// Places subviews evenly around a ring. `gap` shrinks items (1 = touching),
/// `startAngle` rotates the starting position, and `centerItem` pulls the first
/// subview into the middle with the rest ringed around it.
private struct RadialRingLayout: Layout {
    var gap: CGFloat = 1
    var startAngle: Double = 0
    var centerItem: Bool = false
    var centerScale: CGFloat = 1.15   // center diameter as a multiple of ring itemRadius*2

    func sizeThatFits(proposal: ProposedViewSize, subviews _: Subviews, cache _: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        guard !subviews.isEmpty else { return }
        let side = min(bounds.size.width, bounds.size.height)
        let cx = bounds.midX, cy = bounds.midY

        // A single item has no ring to sit on (sin(π) ≈ 0 → zero radius); centre it.
        if subviews.count == 1 {
            place(subviews[0], at: CGPoint(x: cx, y: cy), diameter: side * 0.6)
            return
        }

        let hasCenter = centerItem && subviews.count >= 2
        let ringStart = hasCenter ? 1 : 0
        let ringCount = subviews.count - ringStart

        let m = max(ringCount, 2)
        let angle = Double.pi / Double(m)
        let s = sin(angle)
        let itemRadius = (side / 2.0) * s / (1.0 + s)
        let ringRadius = (side / 2.0) * (1.0 + s).rounded(.down)
        let baseR = ringRadius - itemRadius
        let diameter = 2 * itemRadius * gap
        let step = 2.0 * angle

        if hasCenter {
            let cd = min(2 * itemRadius * centerScale, side * 0.6)
            place(subviews[0], at: CGPoint(x: cx, y: cy), diameter: max(cd, side * 0.1))
        }

        if ringCount == 1 {
            let a = startAngle - .pi / 2
            let r = side * 0.30
            place(subviews[ringStart],
                  at: CGPoint(x: cx + r * cos(a), y: cy + r * sin(a)),
                  diameter: side * 0.30 * gap)
            return
        }

        for j in 0 ..< ringCount {
            let rot = step * Double(j) + startAngle
            var p = CGPoint(x: 0, y: -baseR).applying(CGAffineTransform(rotationAngle: rot))
            p.x += cx; p.y += cy
            place(subviews[ringStart + j], at: p, diameter: diameter)
        }
    }

    private func place(_ sub: LayoutSubview, at center: CGPoint, diameter: CGFloat) {
        sub.place(at: center, anchor: .center,
                  proposal: ProposedViewSize(width: diameter, height: diameter))
    }
}

private enum RingShape: String, CaseIterable, Identifiable {
    case circle = "Circle", rounded = "Rounded"
    var id: String { rawValue }
}

struct RadialLayoutView: View {
    @State private var count: Double = 12
    @State private var gap: Double = 1.0
    @State private var startAngle: Double = 0        // degrees
    @State private var centerItem = false
    @State private var centerGap: Double = 0.15
    @State private var shape: RingShape = .circle
    @State private var centerShape: RingShape = .circle
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var focused: Int?

    private func shapeFor(_ s: RingShape) -> AnyShape {
        switch s {
        case .circle:  return AnyShape(Circle())
        case .rounded: return AnyShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func isCenter(_ i: Int) -> Bool { centerItem && i == 0 }
    private func shape(for i: Int) -> AnyShape { shapeFor(isCenter(i) ? centerShape : shape) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ring
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Radial Layout")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItems) { _, items in
            Task {
                var loaded: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loaded.append(image)
                    }
                }
                images = loaded
            }
        }
    }

    private var ring: some View {
        RadialRingLayout(gap: CGFloat(gap),
                         startAngle: startAngle * .pi / 180,
                         centerItem: centerItem,
                         centerScale: CGFloat(1.3 - centerGap * 0.9)) {
            ForEach(0..<Int(count), id: \.self) { i in
                itemView(i)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { focusOverlay }
        .animation(.snappy, value: count)
        .animation(.snappy, value: gap)
        .animation(.snappy, value: startAngle)
        .animation(.snappy, value: centerItem)
        .animation(.snappy, value: centerGap)
    }

    private func itemView(_ i: Int) -> some View {
        shapeView(for: i)
            .contentShape(shape(for: i))
            .zIndex(isCenter(i) ? 1 : 0)   // keep the centre item above the ring
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { focused = i }
            }
    }

    @ViewBuilder
    private func shapeView(for i: Int) -> some View {
        let s = shape(for: i)
        if images.isEmpty {
            s.fill(Color(hue: Double(i) / max(count, 1), saturation: 0.55, brightness: 1))
        } else {
            Color.clear
                .overlay(Image(uiImage: images[i % images.count]).resizable().scaledToFill())
                .clipShape(s)
        }
    }

    @ViewBuilder
    private var focusOverlay: some View {
        if let f = focused, f < Int(count) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                shapeView(for: f)
                    .frame(width: 200, height: 200)
                    .shadow(radius: 20)
                    .transition(.scale.combined(with: .opacity))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { focused = nil }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Items", $count, 1...24, step: 1, text: "\(Int(count))")
            divider
            sliderRow("Item Size", $gap, 0.4...1.0, text: String(format: "%.0f%%", gap * 100))
            divider
            sliderRow("Start Angle", $startAngle, 0...360, text: "\(Int(startAngle))°")
            divider
            row {
                Toggle("Center Item", isOn: $centerItem)
            }
            if centerItem {
                divider
                sliderRow("Center Gap", $centerGap, 0...1, text: "\(Int(centerGap * 100))%")
                divider
                shapePicker("Center Shape", $centerShape)
            }
            divider
            shapePicker("Ring Shape", $shape)
            divider
            row {
                HStack {
                    Text("Photos").frame(width: 96, alignment: .leading)
                    Spacer()
                    PhotosPicker(selection: $photoItems, matching: .images) {
                        Label(images.isEmpty ? "Choose Photos" : "\(images.count) selected",
                              systemImage: "photo.on.rectangle")
                    }
                    if !images.isEmpty {
                        Button { images = []; photoItems = [] } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var caption: some View {
        Text("A custom `Layout` arranging subviews around a ring. Adjust item size for gaps, "
             + "the start angle, pull one item to the centre, switch shape, and tap any item to "
             + "pop it up close. Add photos to fill the shapes (they cycle). From my-toybox.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, step: Double = 0, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(text).font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
            }
        }
    }

    private func shapePicker(_ label: String, _ selection: Binding<RingShape>) -> some View {
        row {
            HStack {
                Text(label).frame(width: 110, alignment: .leading)
                Spacer()
                Picker(label, selection: selection) {
                    ForEach(RingShape.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).frame(width: 170)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

// MARK: - Wrapping flow layout

/// Lays subviews left-to-right, wrapping to a new row when the width runs out.
private struct WrapFlowLayout: Layout {
    var vSpacing: CGFloat = 8
    var hSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let proposalWidth = proposal.width ?? .zero
        var remainWidth = proposalWidth - hSpacing
        var currentHeight = CGFloat.zero
        var totalSize = CGSize.zero
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: proposalWidth - 2 * hSpacing, height: .infinity))
            if remainWidth - (size.width + hSpacing) < 0 {
                totalSize.height += currentHeight
                remainWidth = proposalWidth - hSpacing
                currentHeight = .zero
            }
            remainWidth -= size.width + hSpacing
            currentHeight = max(size.height + vSpacing, currentHeight)
        }
        totalSize.height += currentHeight + vSpacing
        totalSize.width = proposalWidth
        return totalSize
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var offset = CGPoint(x: hSpacing, y: vSpacing)
        var remainWidth = bounds.width
        var currentHeight = CGFloat.zero
        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: bounds.width - 2 * hSpacing, height: .infinity))
            if remainWidth - (size.width + hSpacing) < 0 {
                offset.y += currentHeight + vSpacing
                offset.x = hSpacing
                currentHeight = .zero
                remainWidth = bounds.width - hSpacing
            }
            let point = CGPoint(x: bounds.origin.x + offset.x, y: bounds.origin.y + offset.y)
            subview.place(at: point, proposal: .init(size))
            offset.x += size.width + hSpacing
            remainWidth -= size.width + hSpacing
            currentHeight = max(size.height, currentHeight)
        }
    }
}

struct FlowLayoutView: View {
    @State private var width: CGFloat = 240

    private let tags = ["Objective-C", "Swift", "SwiftUI", "Ruby", "Python", "JavaScript",
                        "Java", "C++", "C#", "Go", "Kotlin", "Rust", "Metal", "Combine"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    WrapFlowLayout(vSpacing: 8, hSpacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.body).fontWeight(.semibold).fontDesign(.monospaced)
                                .foregroundStyle(.white)
                                .padding(.vertical, 6).padding(.horizontal, 12)
                                .background(.black, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .frame(maxWidth: width)
                    .background(.pink.mix(with: .white, by: 0.5),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.snappy, value: width)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Width").frame(width: 90, alignment: .leading)
                        Slider(value: $width, in: 120...360)
                        Text("\(Int(width))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("A custom `Layout` that flows tags left-to-right and wraps to a new row when "
                     + "the container runs out of width. Drag Width to watch the chips reflow. "
                     + "From my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flow Layout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("Radial") { NavigationStack { RadialLayoutView() } }
#Preview("Flow")   { NavigationStack { FlowLayoutView() } }
