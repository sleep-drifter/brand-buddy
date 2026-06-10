import SwiftUI

// MARK: - VelocityTracker
//
// Value type — embed as @State inside a View.
// Accumulates min/max velocity and returns instantaneous velocity on each update.

struct VelocityTracker {
    private(set) var velocityMin: CGFloat = 0
    private(set) var velocityMax: CGFloat = 0
    private var lastValue: CGFloat = 0
    private var lastTime:  Date    = .distantPast

    /// Reset all state at the start of a new drag session.
    mutating func reset() {
        lastValue   = 0
        lastTime    = .distantPast
        velocityMin = 0
        velocityMax = 0
    }

    /// Call on every gesture `.onChanged`. Returns instantaneous velocity in pts/sec.
    @discardableResult
    mutating func update(rawDelta: CGFloat, at now: Date = Date()) -> CGFloat {
        let dt = now.timeIntervalSince(lastTime)
        let dx = rawDelta - lastValue
        lastValue = rawDelta
        lastTime  = now
        guard dt > 0.001 else { return velocityMax }
        let vel = abs(CGFloat(dx) / CGFloat(dt))
        velocityMin = velocityMin == 0 ? vel : min(velocityMin, vel)
        velocityMax = max(velocityMax, vel)
        return vel
    }
}

// MARK: - TimelineSnapEngine
//
// Pure-function snap helper. No state — callers hold a VelocityTracker separately.

struct TimelineSnapEngine {
    /// Returns the (possibly snapped) delta and whether snapping is active.
    ///
    /// - Parameters:
    ///   - rawDelta:     Raw translation in screen pts (already bounds-clamped by the caller).
    ///   - baseTime:     The timeline time of the edge being dragged (start or end of event).
    ///   - snapPoints:   Times (seconds) to snap to.
    ///   - timeScale:    Screen pts per second.
    ///   - snapRadiusPt: Snap radius in screen pts.
    ///   - velocity:     Current drag velocity in pts/sec (from VelocityTracker).
    ///   - threshold:    Max velocity below which snapping may activate.
    ///
    /// Returns `(rawDelta, false)` unchanged when velocity is too high or no snap point
    /// is within radius. Caller is responsible for re-clamping the returned delta if needed.
    static func snappedDelta(
        rawDelta:    CGFloat,
        baseTime:    Double,
        snapPoints:  [Double],
        timeScale:   CGFloat,
        snapRadiusPt: CGFloat,
        velocity:    CGFloat,
        threshold:   CGFloat
    ) -> (delta: CGFloat, isSnapping: Bool) {
        guard velocity < threshold, timeScale > 0 else { return (rawDelta, false) }
        let rawTime    = baseTime + Double(rawDelta / timeScale)
        let snapRadius = Double(snapRadiusPt / timeScale)
        guard let nearest = snapPoints.min(by: { abs($0 - rawTime) < abs($1 - rawTime) }),
              abs(nearest - rawTime) < snapRadius
        else { return (rawDelta, false) }
        let snappedDelta = CGFloat((nearest - baseTime) * Double(timeScale))
        return (snappedDelta, true)
    }
}
