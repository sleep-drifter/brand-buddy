import SwiftUI
import simd

// Soft-body solver in the matter.js Composites.softBody mold: particles in
// structure-of-arrays SIMD storage, distance constraints, and an iterative
// solver — squish is topology, not an engine feature. Two interchangeable
// solvers share the same constraints:
//
//   Verlet — position integration with implicit velocity; stiffness is the
//   per-iteration relaxation factor. The fast classic.
//
//   XPBD — explicit velocities and compliance-based constraints, so
//   stiffness is independent of iteration count and timestep.
//
// Performance notes: ContiguousArray<SIMD2<Float>> keeps particles packed
// and cache-friendly; collisions go through a flat spatial hash (linked
// cells, zero allocation per frame); the sim runs on a fixed 120 Hz
// accumulator with substeps, and the step cost is measured and exposed for
// the HUD.

enum SoftBodySolver: String, CaseIterable, Identifiable {
    case verlet = "Verlet", xpbd = "XPBD"
    var id: String { rawValue }
}

enum SoftBodyScene: String, CaseIterable, Identifiable {
    case blobs = "Blobs", balloons = "Balloons", cloth = "Cloth & Rope"
    var id: String { rawValue }
}

struct SoftBodyConfig {
    var solver: SoftBodySolver = .verlet
    var stiffness: Float = 0.65      // 0.05…1
    var iterations: Int = 4
    var substeps: Int = 4
    var gravity = SIMD2<Float>(0, 1500)
    var damping: Float = 0.996
    var tearing = true
    var haptics = true
}

final class SoftBodyWorld {

    struct Constraint {
        var a: Int32
        var b: Int32
        var rest: Float
        var lambda: Float = 0
        var tearable = false
        var broken = false
    }

    struct Body {
        enum Kind { case blob, balloon, cloth, rope }
        var kind: Kind
        var range: Range<Int>
        var cols: Int
        var rows: Int
        var hue: Double
        var restArea: Float = 0
    }

    // MARK: Particle storage (SoA)

    private(set) var pos = ContiguousArray<SIMD2<Float>>()
    private var prev = ContiguousArray<SIMD2<Float>>()
    private var vel = ContiguousArray<SIMD2<Float>>()
    private var invMass = ContiguousArray<Float>()
    private var bodyId = ContiguousArray<Int32>()
    private(set) var constraints = ContiguousArray<Constraint>()
    private(set) var bodies: [Body] = []

    let particleRadius: Float = 7
    private let spacing: Float = 16

    var config = SoftBodyConfig()

    // MARK: Scene bookkeeping

    private(set) var scene: SoftBodyScene = .blobs
    private var worldSize = SIMD2<Float>(0, 0)
    private var builtGrid = 0
    private var builtResetToken = -1

    // MARK: Timing / HUD

    private var lastFrame: Date?
    private var accumulator: Float = 0
    private let stepHz: Float = 120
    private var simClock: Float = 0
    private(set) var simMs: Double = 0
    private(set) var frameMs: Double = 0
    private(set) var history = [Double](repeating: 0, count: 90)
    private(set) var historyIdx = 0

    var particleCount: Int { pos.count }
    var constraintCount: Int { constraints.lazy.filter { !$0.broken }.count }

    // MARK: Interaction

    private var grabbed = -1
    private var grabTarget = SIMD2<Float>(0, 0)
    private var maxImpact: Float = 0
    private var lastHapticAt: Float = -1

    // MARK: Spatial hash (flat linked cells, reused buffers)

    private var cellHead: [Int32] = []
    private var cellNext: [Int32] = []
    private var gridW = 1
    private var gridH = 1
    private var cellSize: Float = 14

    // MARK: - Frame entry point

    func advance(now: Date, size: CGSize, scene: SoftBodyScene, blobGrid: Int, resetToken: Int) {
        rebuildIfNeeded(scene: scene, size: size, blobGrid: blobGrid, resetToken: resetToken)

        guard let last = lastFrame else {
            lastFrame = now
            return
        }
        var dt = Float(now.timeIntervalSince(last))
        lastFrame = now
        frameMs = Double(dt) * 1000
        dt = min(dt, 1.0 / 20)
        accumulator += dt

        maxImpact = 0
        let h = 1 / stepHz
        var steps = 0
        let t0 = CFAbsoluteTimeGetCurrent()
        while accumulator >= h, steps < 4 {
            step(h)
            accumulator -= h
            simClock += h
            steps += 1
        }
        if steps > 0 {
            simMs = (CFAbsoluteTimeGetCurrent() - t0) * 1000 / Double(steps)
        }
        historyIdx = (historyIdx + 1) % history.count
        history[historyIdx] = simMs

        if config.haptics, maxImpact > 650, simClock - lastHapticAt > 0.09 {
            lastHapticAt = simClock
            glassMorphHaptic(.soft)
        }
    }

    private func step(_ h: Float) {
        let sub = max(1, config.substeps)
        let dt = h / Float(sub)
        for _ in 0..<sub {
            switch config.solver {
            case .verlet: substepVerlet(dt)
            case .xpbd: substepXPBD(dt)
            }
        }
    }

    // MARK: - Verlet

    private func substepVerlet(_ dt: Float) {
        let g = config.gravity
        let damp = config.damping
        for i in pos.indices where invMass[i] > 0 {
            let p = pos[i]
            let v = (p - prev[i]) * damp
            prev[i] = p
            pos[i] = p + v + g * (dt * dt)
        }
        applyGrab()
        applyPressure()

        let k = config.stiffness
        for _ in 0..<max(1, config.iterations) {
            for ci in constraints.indices {
                if constraints[ci].broken { continue }
                let c = constraints[ci]
                let ia = Int(c.a), ib = Int(c.b)
                let wa = invMass[ia], wb = invMass[ib]
                let wsum = wa + wb
                if wsum == 0 { continue }
                let d = pos[ib] - pos[ia]
                let len = simd_length(d)
                if len < 1e-5 { continue }
                if config.tearing, c.tearable, len > c.rest * 2.6 {
                    constraints[ci].broken = true
                    continue
                }
                let corr = d * ((len - c.rest) / len * k)
                pos[ia] += corr * (wa / wsum)
                pos[ib] -= corr * (wb / wsum)
            }
            collide()
        }
    }

    // MARK: - XPBD

    private func substepXPBD(_ dt: Float) {
        let g = config.gravity
        let damp = config.damping
        for i in pos.indices where invMass[i] > 0 {
            vel[i] = (vel[i] + g * dt) * damp
            prev[i] = pos[i]
            pos[i] += vel[i] * dt
        }
        applyGrab()
        applyPressure()

        // Compliance: 0 at full stiffness, growing rapidly as the slider drops.
        let soft = 1 - config.stiffness
        let alpha = soft * soft * soft * 0.0002
        let alphaTilde = alpha / (dt * dt)

        for ci in constraints.indices {
            constraints[ci].lambda = 0
        }
        for _ in 0..<max(1, config.iterations) {
            for ci in constraints.indices {
                if constraints[ci].broken { continue }
                let c = constraints[ci]
                let ia = Int(c.a), ib = Int(c.b)
                let wa = invMass[ia], wb = invMass[ib]
                let wsum = wa + wb
                if wsum == 0 { continue }
                let d = pos[ib] - pos[ia]
                let len = simd_length(d)
                if len < 1e-5 { continue }
                if config.tearing, c.tearable, len > c.rest * 2.6 {
                    constraints[ci].broken = true
                    continue
                }
                let C = len - c.rest
                let dLambda = (-C - alphaTilde * c.lambda) / (wsum + alphaTilde)
                constraints[ci].lambda += dLambda
                let corr = (d / len) * dLambda
                pos[ia] -= corr * wa
                pos[ib] += corr * wb
            }
            collide()
        }

        let invDt = 1 / dt
        for i in pos.indices where invMass[i] > 0 {
            vel[i] = (pos[i] - prev[i]) * invDt
        }
    }

    // MARK: - Shared forces

    private func applyGrab() {
        guard grabbed >= 0, grabbed < pos.count else { return }
        let p = pos[grabbed]
        pos[grabbed] = p + (grabTarget - p) * 0.6
    }

    /// Gas pressure for balloon rings: compare current polygon area to rest
    /// area and displace each vertex along its outward normal. Rings are
    /// built with positive shoelace winding, so the outward normal of the
    /// chord (next − prev) is (chord.y, −chord.x).
    private func applyPressure() {
        for body in bodies where body.kind == .balloon {
            let r = body.range
            let n = r.count
            guard n > 2, body.restArea > 1 else { continue }

            var area: Float = 0
            var j = r.upperBound - 1
            for i in r {
                area += pos[j].x * pos[i].y - pos[i].x * pos[j].y
                j = i
            }
            area *= 0.5

            let ratio = (body.restArea - area) / body.restArea
            let push = min(max(ratio, -0.5), 0.5) * 2.4
            if abs(push) < 0.001 { continue }

            for k in 0..<n {
                let i = r.lowerBound + k
                if invMass[i] == 0 { continue }
                let pn = pos[r.lowerBound + (k + 1) % n]
                let pp = pos[r.lowerBound + (k + n - 1) % n]
                let chord = pn - pp
                let len = simd_length(chord)
                if len < 1e-5 { continue }
                let normal = SIMD2<Float>(chord.y, -chord.x) / len
                pos[i] += normal * push
            }
        }
    }

    // MARK: - Collisions

    private func collide() {
        let r = particleRadius
        let lo = SIMD2<Float>(r, r)
        let hi = worldSize - SIMD2<Float>(r, r)
        guard hi.x > lo.x, hi.y > lo.y else { return }

        for i in pos.indices {
            var p = pos[i]
            let v = p - prev[i]
            if p.x < lo.x { p.x = lo.x; prev[i].x = p.x + v.x * 0.4; maxImpact = max(maxImpact, abs(v.x) * stepHz) }
            if p.x > hi.x { p.x = hi.x; prev[i].x = p.x + v.x * 0.4; maxImpact = max(maxImpact, abs(v.x) * stepHz) }
            if p.y < lo.y { p.y = lo.y; prev[i].y = p.y + v.y * 0.4; maxImpact = max(maxImpact, abs(v.y) * stepHz) }
            if p.y > hi.y { p.y = hi.y; prev[i].y = p.y + v.y * 0.4; maxImpact = max(maxImpact, abs(v.y) * stepHz) }
            pos[i] = p
        }

        rebuildGrid()
        let minDist = r * 2
        let minDistSq = minDist * minDist
        for i in pos.indices {
            let pi = pos[i]
            let cx = min(max(Int(pi.x / cellSize), 0), gridW - 1)
            let cy = min(max(Int(pi.y / cellSize), 0), gridH - 1)
            for oy in -1...1 {
                let ny = cy + oy
                if ny < 0 || ny >= gridH { continue }
                for ox in -1...1 {
                    let nx = cx + ox
                    if nx < 0 || nx >= gridW { continue }
                    var j = Int(cellHead[ny * gridW + nx])
                    while j >= 0 {
                        defer { j = Int(cellNext[j]) }
                        if j <= i { continue }
                        if bodyId[i] == bodyId[j] { continue }
                        let d = pos[j] - pi
                        let distSq = simd_length_squared(d)
                        if distSq >= minDistSq || distSq < 1e-8 { continue }
                        let dist = distSq.squareRoot()
                        let wa = invMass[i], wb = invMass[j]
                        let wsum = wa + wb
                        if wsum == 0 { continue }
                        let corr = d * ((dist - minDist) / dist)
                        pos[i] += corr * (wa / wsum)
                        pos[j] -= corr * (wb / wsum)
                        maxImpact = max(maxImpact, (minDist - dist) * stepHz * 0.5)
                    }
                }
            }
        }
    }

    private func rebuildGrid() {
        cellSize = particleRadius * 2
        gridW = max(1, Int(worldSize.x / cellSize) + 1)
        gridH = max(1, Int(worldSize.y / cellSize) + 1)
        let cells = gridW * gridH
        if cellHead.count != cells {
            cellHead = [Int32](repeating: -1, count: cells)
        } else {
            for k in cellHead.indices { cellHead[k] = -1 }
        }
        if cellNext.count != pos.count {
            cellNext = [Int32](repeating: -1, count: pos.count)
        }
        for i in pos.indices {
            let cx = min(max(Int(pos[i].x / cellSize), 0), gridW - 1)
            let cy = min(max(Int(pos[i].y / cellSize), 0), gridH - 1)
            let idx = cy * gridW + cx
            cellNext[i] = cellHead[idx]
            cellHead[idx] = Int32(i)
        }
    }

    // MARK: - Interaction API

    func drag(to point: CGPoint) {
        let target = SIMD2<Float>(Float(point.x), Float(point.y))
        grabTarget = target
        guard grabbed < 0 else { return }
        var best = -1
        var bestDistSq: Float = 44 * 44
        for i in pos.indices where invMass[i] > 0 {
            let dsq = simd_length_squared(pos[i] - target)
            if dsq < bestDistSq {
                bestDistSq = dsq
                best = i
            }
        }
        grabbed = best
    }

    func endDrag(flingPointsPerSecond: CGSize) {
        guard grabbed >= 0, grabbed < pos.count else { grabbed = -1; return }
        let v = SIMD2<Float>(Float(flingPointsPerSecond.width), Float(flingPointsPerSecond.height))
        let capped = simd_clamp(v, SIMD2(repeating: -2400), SIMD2(repeating: 2400))
        let dt = 1 / stepHz
        prev[grabbed] = pos[grabbed] - capped * dt
        vel[grabbed] = capped
        grabbed = -1
    }

    var grabbedPoint: CGPoint? {
        guard grabbed >= 0, grabbed < pos.count else { return nil }
        return CGPoint(x: CGFloat(pos[grabbed].x), y: CGFloat(pos[grabbed].y))
    }

    // MARK: - Scene building

    private func rebuildIfNeeded(scene: SoftBodyScene, size: CGSize, blobGrid: Int, resetToken: Int) {
        let s = SIMD2<Float>(Float(size.width), Float(size.height))
        let dirty = scene != self.scene
            || s != worldSize
            || blobGrid != builtGrid
            || resetToken != builtResetToken
            || pos.isEmpty
        guard dirty, s.x > 40, s.y > 40 else { return }

        self.scene = scene
        worldSize = s
        builtGrid = blobGrid
        builtResetToken = resetToken

        pos.removeAll(keepingCapacity: true)
        prev.removeAll(keepingCapacity: true)
        vel.removeAll(keepingCapacity: true)
        invMass.removeAll(keepingCapacity: true)
        bodyId.removeAll(keepingCapacity: true)
        constraints.removeAll(keepingCapacity: true)
        bodies.removeAll()
        grabbed = -1
        accumulator = 0

        let w = s.x, h = s.y
        switch scene {
        case .blobs:
            let g = max(4, blobGrid)
            addBlob(center: SIMD2(w * 0.42, h * 0.28), cols: g, rows: g, hue: 0.58)
            addBlob(center: SIMD2(w * 0.20, h * 0.62), cols: max(3, g - 2), rows: max(3, g - 2), hue: 0.75)
            addBlob(center: SIMD2(w * 0.66, h * 0.66), cols: g + 2, rows: max(3, g / 2), hue: 0.05)
        case .balloons:
            addBalloon(center: SIMD2(w * 0.34, h * 0.32), radius: min(w, h) * 0.16, count: 22, hue: 0.33)
            addBalloon(center: SIMD2(w * 0.64, h * 0.28), radius: min(w, h) * 0.12, count: 18, hue: 0.9)
            addBlob(center: SIMD2(w * 0.5, h * 0.72), cols: 4, rows: 4, hue: 0.58)
        case .cloth:
            addCloth(origin: SIMD2(w * 0.08, h * 0.08), cols: 12, rows: 8)
            addRope(from: SIMD2(w * 0.86, h * 0.06), links: 11)
        }
    }

    /// Extra blob dropped in at runtime (Blobs scene stress control).
    func spawnBlob() {
        guard pos.count < 1600 else { return }
        let x = Float.random(in: worldSize.x * 0.25...worldSize.x * 0.7)
        addBlob(center: SIMD2(x, worldSize.y * 0.14), cols: 4, rows: 4,
                hue: Double.random(in: 0...1))
    }

    private func newParticle(_ p: SIMD2<Float>, invM: Float, body: Int32) {
        pos.append(p)
        prev.append(p)
        vel.append(.zero)
        invMass.append(invM)
        bodyId.append(body)
    }

    private func addConstraint(_ a: Int, _ b: Int, tearable: Bool = false) {
        let rest = simd_length(pos[b] - pos[a])
        constraints.append(Constraint(a: Int32(a), b: Int32(b), rest: rest, tearable: tearable))
    }

    private func addBlob(center: SIMD2<Float>, cols: Int, rows: Int, hue: Double) {
        let start = pos.count
        let id = Int32(bodies.count)
        let origin = center - SIMD2(Float(cols - 1), Float(rows - 1)) * spacing * 0.5
        for r in 0..<rows {
            for c in 0..<cols {
                newParticle(origin + SIMD2(Float(c), Float(r)) * spacing, invM: 1, body: id)
            }
        }
        // Cross-braced mesh, matter.js style: edges plus both diagonals.
        for r in 0..<rows {
            for c in 0..<cols {
                let i = start + r * cols + c
                if c + 1 < cols { addConstraint(i, i + 1) }
                if r + 1 < rows { addConstraint(i, i + cols) }
                if c + 1 < cols, r + 1 < rows {
                    addConstraint(i, i + cols + 1)
                    addConstraint(i + 1, i + cols)
                }
            }
        }
        bodies.append(Body(kind: .blob, range: start..<pos.count, cols: cols, rows: rows, hue: hue))
    }

    private func addBalloon(center: SIMD2<Float>, radius: Float, count: Int, hue: Double) {
        let start = pos.count
        let id = Int32(bodies.count)
        for k in 0..<count {
            let t = Float(k) / Float(count) * 2 * .pi
            newParticle(center + SIMD2(cos(t), sin(t)) * radius, invM: 1, body: id)
        }
        for k in 0..<count {
            addConstraint(start + k, start + (k + 1) % count)
            addConstraint(start + k, start + (k + 2) % count)  // bending support
        }
        var body = Body(kind: .balloon, range: start..<pos.count, cols: count, rows: 1, hue: hue)
        var area: Float = 0
        var j = count - 1
        for i in 0..<count {
            area += pos[start + j].x * pos[start + i].y - pos[start + i].x * pos[start + j].y
            j = i
        }
        body.restArea = area * 0.5
        bodies.append(body)
    }

    private func addCloth(origin: SIMD2<Float>, cols: Int, rows: Int) {
        let start = pos.count
        let id = Int32(bodies.count)
        for r in 0..<rows {
            for c in 0..<cols {
                let pinned = r == 0 && (c % 3 == 0 || c == cols - 1)
                newParticle(origin + SIMD2(Float(c), Float(r)) * spacing,
                            invM: pinned ? 0 : 1, body: id)
            }
        }
        for r in 0..<rows {
            for c in 0..<cols {
                let i = start + r * cols + c
                if c + 1 < cols { addConstraint(i, i + 1, tearable: true) }
                if r + 1 < rows { addConstraint(i, i + cols, tearable: true) }
            }
        }
        bodies.append(Body(kind: .cloth, range: start..<pos.count, cols: cols, rows: rows, hue: 0.52))
    }

    private func addRope(from anchor: SIMD2<Float>, links: Int) {
        let start = pos.count
        let id = Int32(bodies.count)
        for k in 0...links {
            newParticle(anchor + SIMD2(0, Float(k)) * spacing, invM: k == 0 ? 0 : 1, body: id)
        }
        for k in 0..<links {
            addConstraint(start + k, start + k + 1, tearable: true)
        }
        bodies.append(Body(kind: .rope, range: start..<pos.count, cols: 1, rows: links + 1, hue: 0.12))

        // A small weight blob welded to the rope's tail.
        let tail = pos.count - 1
        let weightCenter = pos[tail] + SIMD2(0, spacing * 1.5)
        addBlob(center: weightCenter, cols: 3, rows: 3, hue: 0.12)
        let weightTop = bodies[bodies.count - 1].range.lowerBound + 1
        addConstraint(tail, weightTop)
    }

    // MARK: - Rendering

    func draw(in ctx: inout GraphicsContext, wireframe: Bool) {
        guard !pos.isEmpty else { return }

        if wireframe {
            var lines = Path()
            for c in constraints where !c.broken {
                lines.move(to: point(Int(c.a)))
                lines.addLine(to: point(Int(c.b)))
            }
            ctx.stroke(lines, with: .color(.white.opacity(0.65)), lineWidth: 0.8)

            var circles = Path()
            let r = CGFloat(particleRadius)
            for i in pos.indices {
                let p = point(i)
                circles.addEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
            }
            ctx.stroke(circles, with: .color(.white.opacity(0.22)), lineWidth: 0.6)
        } else {
            for body in bodies {
                switch body.kind {
                case .blob:
                    fillSmooth(hull: blobHull(body), hue: body.hue, in: &ctx)
                case .balloon:
                    fillSmooth(hull: Array(body.range), hue: body.hue, in: &ctx)
                case .cloth:
                    var lines = Path()
                    for c in constraints where !c.broken
                        && body.range.contains(Int(c.a)) && body.range.contains(Int(c.b)) {
                        lines.move(to: point(Int(c.a)))
                        lines.addLine(to: point(Int(c.b)))
                    }
                    ctx.stroke(lines, with: .color(Color(hue: body.hue, saturation: 0.5, brightness: 0.95).opacity(0.9)), lineWidth: 1.4)
                case .rope:
                    var line = Path()
                    var first = true
                    for i in body.range {
                        if first { line.move(to: point(i)); first = false }
                        else { line.addLine(to: point(i)) }
                    }
                    ctx.stroke(line, with: .color(Color(hue: body.hue, saturation: 0.6, brightness: 0.95)), lineWidth: 3)
                }
            }
        }

        if let g = grabbedPoint {
            let ring = Path(ellipseIn: CGRect(x: g.x - 14, y: g.y - 14, width: 28, height: 28))
            ctx.stroke(ring, with: .color(.cyan.opacity(0.9)), lineWidth: 1.5)
        }
    }

    private func point(_ i: Int) -> CGPoint {
        CGPoint(x: CGFloat(pos[i].x), y: CGFloat(pos[i].y))
    }

    /// Perimeter particle indices of a grid blob, clockwise.
    private func blobHull(_ body: Body) -> [Int] {
        let s = body.range.lowerBound
        let cols = body.cols, rows = body.rows
        var out: [Int] = []
        for c in 0..<cols { out.append(s + c) }
        for r in 1..<rows { out.append(s + r * cols + (cols - 1)) }
        if rows > 1 {
            for c in stride(from: cols - 2, through: 0, by: -1) {
                out.append(s + (rows - 1) * cols + c)
            }
        }
        for r in stride(from: rows - 2, through: 1, by: -1) {
            out.append(s + r * cols)
        }
        return out
    }

    /// Closed midpoint-smoothed path through hull particles.
    private func fillSmooth(hull: [Int], hue: Double, in ctx: inout GraphicsContext) {
        guard hull.count > 2 else { return }
        var path = Path()
        let pts = hull.map(point)
        let n = pts.count
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        }
        path.move(to: mid(pts[0], pts[1]))
        for k in 1...n {
            let p1 = pts[k % n]
            let p2 = pts[(k + 1) % n]
            path.addQuadCurve(to: mid(p1, p2), control: p1)
        }
        path.closeSubpath()
        let color = Color(hue: hue, saturation: 0.6, brightness: 0.95)
        ctx.fill(path, with: .color(color.opacity(0.8)))
        ctx.stroke(path, with: .color(.white.opacity(0.55)), lineWidth: 1)
    }
}
