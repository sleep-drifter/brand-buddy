//  RadialRingLayout.swift
//  RadialLayout
//
//  A pure-SwiftUI `Layout` that places subviews evenly around a ring,
//  optionally pulling one subview into the middle.
//
//  Exported from DesignerBuddy's Radial Layout playground; layout math
//  adapted from Koshimizu-Takehito's my-toybox. No UIKit, no Metal.

import CoreGraphics
import SwiftUI

/// Places subviews evenly around a ring.
///
/// Ring items are sized so that at `itemScale == 1` adjacent items touch and
/// the whole ring exactly fills the shorter side of the proposed bounds.
///
/// When `centerItem` is true, the **last** subview is pulled into the middle
/// and the remaining subviews form the ring. The centre must be the last
/// subview because `zIndex` is not honoured inside a custom `Layout` —
/// painting order is structural order, and last-emitted draws on top.
/// Use ``RadialRing`` if you'd rather not manage that ordering yourself.
@available(iOS 16.0, *)
public struct RadialRingLayout: Layout {
    /// Scales ring items relative to the size at which neighbours touch
    /// (`1` = touching; smaller values open gaps, larger values overlap).
    public var itemScale: CGFloat
    /// Rotates the first ring position clockwise from 12 o'clock.
    public var startAngle: Angle
    /// Pulls the last subview into the middle with the rest ringed around it.
    public var centerItem: Bool
    /// Centre item diameter as a multiple of a ring item's diameter.
    public var centerScale: CGFloat

    public init(itemScale: CGFloat = 1,
                startAngle: Angle = .zero,
                centerItem: Bool = false,
                centerScale: CGFloat = 1.15) {
        self.itemScale = itemScale
        self.startAngle = startAngle
        self.centerItem = centerItem
        self.centerScale = centerScale
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews _: Subviews, cache _: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    public func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        guard !subviews.isEmpty else { return }
        let side = min(bounds.size.width, bounds.size.height)
        let cx = bounds.midX, cy = bounds.midY

        // A single item has no ring to sit on (sin(π) ≈ 0 → zero radius); centre it.
        if subviews.count == 1 {
            place(subviews[0], at: CGPoint(x: cx, y: cy), diameter: side * 0.6)
            return
        }

        let hasCenter = centerItem && subviews.count >= 2
        let ringCount = hasCenter ? subviews.count - 1 : subviews.count
        let centerIndex = subviews.count - 1

        let m = max(ringCount, 2)
        let angle = Double.pi / Double(m)
        let s = sin(angle)
        // Items of radius r on a ring of radius R touch neighbours when r = R·sin,
        // and fit the frame when R + r = side/2 → R = (side/2)/(1+sin).
        let itemRadius = (side / 2.0) * s / (1.0 + s)
        let baseR = (side / 2.0) / (1.0 + s)
        let diameter = 2 * itemRadius * itemScale
        let step = 2.0 * angle

        if hasCenter {
            let cd = min(2 * itemRadius * centerScale, side * 0.6)
            place(subviews[centerIndex], at: CGPoint(x: cx, y: cy), diameter: max(cd, side * 0.1))
        }

        // A one-item ring around a centre: park it at the start angle on a
        // mid-radius orbit rather than dividing the circle.
        if ringCount == 1 {
            let a = startAngle.radians - .pi / 2
            let r = side * 0.30
            place(subviews[0],
                  at: CGPoint(x: cx + r * cos(a), y: cy + r * sin(a)),
                  diameter: side * 0.30 * itemScale)
            return
        }

        for j in 0 ..< ringCount {
            let rot = step * Double(j) + startAngle.radians
            var p = CGPoint(x: 0, y: -baseR).applying(CGAffineTransform(rotationAngle: rot))
            p.x += cx; p.y += cy
            place(subviews[j], at: p, diameter: diameter)
        }
    }

    private func place(_ sub: LayoutSubview, at center: CGPoint, diameter: CGFloat) {
        sub.place(at: center, anchor: .center,
                  proposal: ProposedViewSize(width: diameter, height: diameter))
    }
}

/// Convenience container over ``RadialRingLayout`` that manages subview order
/// for you: ring content first, centre content last, so the centre draws on top.
///
/// Pass ring items directly (a `ForEach` or a list of views) — don't wrap them
/// in a stack, or the stack becomes a single ring item. The `center` builder
/// should resolve to exactly one view.
@available(iOS 16.0, *)
public struct RadialRing<Ring: View, Center: View>: View {
    private let itemScale: CGFloat
    private let startAngle: Angle
    private let centerScale: CGFloat
    private let hasCenter: Bool
    private let ring: Ring
    private let center: Center

    /// A ring of items around a centre item.
    public init(itemScale: CGFloat = 1,
                startAngle: Angle = .zero,
                centerScale: CGFloat = 1.15,
                @ViewBuilder ring: () -> Ring,
                @ViewBuilder center: () -> Center) {
        self.itemScale = itemScale
        self.startAngle = startAngle
        self.centerScale = centerScale
        self.hasCenter = true
        self.ring = ring()
        self.center = center()
    }

    public var body: some View {
        RadialRingLayout(itemScale: itemScale,
                         startAngle: startAngle,
                         centerItem: hasCenter,
                         centerScale: centerScale) {
            ring
            if hasCenter { center }
        }
    }
}

@available(iOS 16.0, *)
extension RadialRing where Center == EmptyView {
    /// A ring of items with nothing in the middle.
    public init(itemScale: CGFloat = 1,
                startAngle: Angle = .zero,
                @ViewBuilder ring: () -> Ring) {
        self.itemScale = itemScale
        self.startAngle = startAngle
        self.centerScale = 1.15
        self.hasCenter = false
        self.ring = ring()
        self.center = EmptyView()
    }
}

#Preview("RadialRing") {
    RadialRing(itemScale: 1.0, centerScale: 1.165) {
        ForEach(1..<7, id: \.self) { i in
            Circle().fill(Color(hue: Double(i) / 7, saturation: 0.55, brightness: 1))
        }
    } center: {
        Circle().fill(Color(hue: 0, saturation: 0.55, brightness: 1))
    }
    .aspectRatio(1, contentMode: .fit)
    .padding(20)
    .background(Color.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .padding()
}
