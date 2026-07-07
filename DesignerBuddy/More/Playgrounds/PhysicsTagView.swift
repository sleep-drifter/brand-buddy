import CoreMotion
import SpriteKit
import SwiftUI
import UIKit

// Physics tag-cloud playground ported from Koshimizu-Takehito's my-toybox, extended
// with tunable tag count, gravity strength, bounciness, and tag size (padding).
// SpriteKit physics + CoreMotion: gravity follows device tilt, drag to fling tags.

// MARK: - Screen

struct PhysicsTagView: View {
    @State private var scene: PhysicsTagScene = {
        let scene = PhysicsTagScene()
        scene.scaleMode = .resizeFill
        return scene
    }()
    @State private var usesDeviceMotion = true
    @State private var tagCount: Double = 20
    @State private var gravity: Double = 1.0
    @State private var bounciness: Double = 0.2
    @State private var tagSize: Double = 1.0
    @State private var showControls = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea(edges: .bottom)
            .modifier(ParamSync(scene: scene,
                                usesDeviceMotion: usesDeviceMotion,
                                gravity: gravity,
                                bounciness: bounciness,
                                tagCount: tagCount,
                                tagSize: tagSize,
                                colorScheme: colorScheme))
            .tint(.blue)
            .navigationTitle("Physics Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showControls = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showControls) {
                controlsSheet
                    .presentationDetents([.height(320)])
                    .presentationBackgroundInteraction(.enabled)
                    .presentationDragIndicator(.visible)
            }
    }

    private var controlsSheet: some View {
        VStack(spacing: 14) {
            HStack {
                Toggle("Gyroscope", isOn: $usesDeviceMotion).fixedSize()
                Spacer()
                Button { scene.resetSimulation() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
            slider("Tags", $tagCount, 5...40, step: 1, text: "\(Int(tagCount.rounded()))") {
                scene.resetSimulation()
            }
            slider("Gravity", $gravity, 0...2, text: String(format: "%.1f", gravity))
            slider("Bounce", $bounciness, 0...1, text: String(format: "%.2f", bounciness))
            slider("Size", $tagSize, 0.5...2, text: String(format: "%.1f", tagSize)) {
                scene.resetSimulation()
            }
            Spacer(minLength: 0)
        }
        .padding()
        .presentationBackground(.regularMaterial)
    }

    private func slider(_ label: String,
                        _ value: Binding<Double>,
                        _ range: ClosedRange<Double>,
                        step: Double = 0,
                        text: String,
                        onCommit: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 12) {
            Text(label).frame(width: 64, alignment: .leading)
            Group {
                if step > 0 {
                    Slider(value: value, in: range, step: step) { editing in if !editing { onCommit() } }
                } else {
                    Slider(value: value, in: range) { editing in if !editing { onCommit() } }
                }
            }
            Text(text).font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary).frame(width: 34, alignment: .trailing)
        }
        .font(.subheadline)
    }
}

// MARK: - Parameter sync

/// Pushes control changes into the scene. Kept as its own modifier so the screen's
/// `body` stays a short chain the type-checker can resolve quickly.
private struct ParamSync: ViewModifier {
    let scene: PhysicsTagScene
    let usesDeviceMotion: Bool
    let gravity: Double
    let bounciness: Double
    let tagCount: Double
    let tagSize: Double
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .onChange(of: usesDeviceMotion) { _, v in scene.usesDeviceMotion = v }
            .onChange(of: gravity) { _, v in scene.gravityStrength = CGFloat(v) }
            .onChange(of: bounciness) { _, v in scene.bounciness = CGFloat(v) }
            .onChange(of: tagCount) { _, v in scene.tagCount = Int(v.rounded()) }
            .onChange(of: tagSize) { _, v in scene.sizeScale = CGFloat(v) }
            .onChange(of: colorScheme) { _, _ in scene.backgroundColor = .systemBackground }
    }
}

// MARK: - Scene

final class PhysicsTagScene: SKScene {
    private let motionManager = CMMotionManager()
    private let spawnRunner = SKNode()
    private var draggedNode: SKSpriteNode?
    private var dragOffset: CGPoint = .zero
    private var lastDragPosition: CGPoint = .zero
    private var lastDragTimestamp: TimeInterval = 0
    private var hasSpawnedInitially = false
    private var textureCache: [TextureKey: SKTexture] = [:]

    // MARK: Tunable parameters

    var tagCount: Int = 20
    var sizeScale: CGFloat = 1.0 {
        didSet { textureCache.removeAll() }
    }
    var gravityStrength: CGFloat = 1.0 {
        didSet {
            if !usesDeviceMotion {
                physicsWorld.gravity = CGVector(dx: 0, dy: -9.8 * gravityStrength)
            }
        }
    }
    var bounciness: CGFloat = 0.2 {
        didSet {
            enumerateChildNodes(withName: Self.tagNodeName) { node, _ in
                node.physicsBody?.restitution = self.bounciness
            }
        }
    }

    var usesDeviceMotion = true {
        didSet {
            guard usesDeviceMotion != oldValue else { return }
            if usesDeviceMotion {
                startMotionUpdates()
            } else {
                motionManager.stopDeviceMotionUpdates()
                physicsWorld.gravity = CGVector(dx: 0, dy: -9.8 * gravityStrength)
            }
        }
    }
}

// MARK: - Lifecycle

extension PhysicsTagScene {
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        anchorPoint = .zero
        backgroundColor = .systemBackground
        updatePhysicsBounds()
        if spawnRunner.parent == nil {
            spawnRunner.zPosition = -10000
            addChild(spawnRunner)
        }
        startMotionUpdates()
        spawnTagsIfLayoutReady()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        releaseDraggedNode()
        motionManager.stopDeviceMotionUpdates()
        removeAllActions()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != size else { return }
        updatePhysicsBounds()
        spawnTagsIfLayoutReady()
    }

    private func updatePhysicsBounds() {
        let extraHeight = physicsTopExtension(for: size)
        physicsBody = SKPhysicsBody(
            edgeLoopFrom: CGRect(x: 0, y: 0, width: size.width, height: size.height + extraHeight)
        )
    }
}

// MARK: - CoreMotion

private extension PhysicsTagScene {
    func startMotionUpdates() {
        #if !targetEnvironment(simulator)
        guard !motionManager.isDeviceMotionActive else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let gravity = motion?.gravity else { return }
            let g = 9.8 * self.gravityStrength
            self.physicsWorld.gravity = CGVector(dx: gravity.x * g, dy: gravity.y * g)
        }
        #endif
    }
}

// MARK: - Geometry (scales with sizeScale; the label font stays fixed so the
// control reads as tag padding)

extension PhysicsTagScene {
    private static let tagNodeName = "physicsTag"
    private static let tagFont = UIFont.systemFont(ofSize: 14, weight: .bold)

    private var tagHeight: CGFloat { 36 * sizeScale }
    private var dotDiameter: CGFloat { 10 * sizeScale }
    private var leftPadding: CGFloat { 8 * sizeScale }
    private var dotTextGap: CGFloat { 6 * sizeScale }
    private var rightPadding: CGFloat { 10 * sizeScale }
    private var textWidth: CGFloat {
        ceil(NSAttributedString(string: "example", attributes: [.font: Self.tagFont]).size().width)
    }
    private var tagWidth: CGFloat { leftPadding + dotDiameter + dotTextGap + textWidth + rightPadding }
    private var enclosingRadius: CGFloat { 0.5 * hypot(tagWidth, tagHeight) }
}

// MARK: - Spawn

extension PhysicsTagScene {
    private static let spawnInterval: TimeInterval = 0.15
    private static let maxSpawnZRotation: CGFloat = .pi / 2.2
    private static let spawnWallPadding: CGFloat = 2
    private static let spawnBandAboveScreen: CGFloat = 4
    private static let spawnAttemptsPerTag = 5000
    private static let spawnBatchRetries = 5
    private static let maxThrowSpeed: CGFloat = 2000
    private static let minimumDragDeltaTime: TimeInterval = 1e-4

    private struct SpawnSpecification {
        var position: CGPoint
        var rotation: CGFloat
    }

    private func physicsWorldTotalHeight() -> CGFloat {
        size.height + physicsTopExtension(for: size)
    }

    private func buildSpawnSpecifications() -> [SpawnSpecification] {
        let r = enclosingRadius
        let d = 2 * r
        let pad = Self.spawnWallPadding
        let xMin = r + pad
        let xMax = size.width - r - pad
        let yMin = size.height + r + Self.spawnBandAboveScreen
        let yMax = physicsWorldTotalHeight() - r - pad
        guard xMin <= xMax, yMin <= yMax else { return [] }
        let dSq = d * d

        for _ in 0 ..< Self.spawnBatchRetries {
            var centers: [CGPoint] = []
            centers.reserveCapacity(tagCount)
            var success = true
            for _ in 0 ..< tagCount {
                var placed = false
                for _ in 0 ..< Self.spawnAttemptsPerTag {
                    let cx = CGFloat.random(in: xMin ... xMax)
                    let cy = CGFloat.random(in: yMin ... yMax)
                    let overlaps = centers.contains { existing in
                        let dx = cx - existing.x
                        let dy = cy - existing.y
                        return dx * dx + dy * dy < dSq
                    }
                    if !overlaps {
                        centers.append(CGPoint(x: cx, y: cy))
                        placed = true
                        break
                    }
                }
                if !placed { success = false; break }
            }
            if success {
                return centers.map { center in
                    SpawnSpecification(
                        position: center,
                        rotation: CGFloat.random(in: -Self.maxSpawnZRotation ... Self.maxSpawnZRotation)
                    )
                }
            }
        }
        return []
    }

    private func physicsTopExtension(for sceneSize: CGSize) -> CGFloat {
        let r = enclosingRadius
        let pad = Self.spawnWallPadding
        let xRange = sceneSize.width - 2 * (r + pad)
        guard xRange > 0 else { return 4 * r }
        let totalCircleArea = CGFloat(tagCount) * .pi * r * r
        let targetPackingFraction: CGFloat = 0.25
        let yRange = totalCircleArea / (targetPackingFraction * xRange)
        return yRange + 2 * r + pad + Self.spawnBandAboveScreen
    }

    private func spawnTagsIfLayoutReady() {
        guard !hasSpawnedInitially else { return }
        guard size.width > tagWidth, size.height > tagHeight else { return }
        hasSpawnedInitially = true
        spawnTags()
    }

    private func spawnTags() {
        let specs = buildSpawnSpecifications().shuffled()
        let all = PhysicsTagColor.allCases
        let colors = (0 ..< tagCount).map { all[$0 % all.count] }.shuffled()
        let actions: [SKAction] = colors.enumerated().map { index, color in
            .sequence([
                .wait(forDuration: Self.spawnInterval),
                .run { [weak self] in
                    guard let self, index < specs.count else { return }
                    let s = specs[index]
                    self.addTagNode(color: color, zOrder: index, position: s.position, rotation: s.rotation)
                },
            ])
        }
        spawnRunner.run(.sequence(actions))
    }

    func resetSimulation() {
        spawnRunner.removeAllActions()
        removeAllActions()
        releaseDraggedNode()
        hasSpawnedInitially = false
        enumerateChildNodes(withName: Self.tagNodeName) { node, _ in node.removeFromParent() }
        updatePhysicsBounds()
        if usesDeviceMotion {
            #if targetEnvironment(simulator)
            physicsWorld.gravity = CGVector(dx: 0, dy: -9.8 * gravityStrength)
            #else
            startMotionUpdates()
            #endif
        } else {
            motionManager.stopDeviceMotionUpdates()
            physicsWorld.gravity = CGVector(dx: 0, dy: -9.8 * gravityStrength)
        }
        spawnTagsIfLayoutReady()
    }

    private func addTagNode(color: PhysicsTagColor, zOrder: Int, position: CGPoint, rotation: CGFloat) {
        guard size.width > tagWidth, size.height > tagHeight else { return }
        let node = makeTagNode(color: color)
        node.position = position
        node.zRotation = rotation
        node.zPosition = CGFloat(zOrder)
        addChild(node)
    }
}

// MARK: - Tag Node

extension PhysicsTagScene {
    private func makeTagNode(color: PhysicsTagColor) -> SKSpriteNode {
        let key = TextureKey(color: color, scale: sizeScale)
        let texture = textureCache[key] ?? {
            let tex = SKTexture(image: renderTagImage(color: color))
            textureCache[key] = tex
            return tex
        }()
        let tagSize = CGSize(width: tagWidth, height: tagHeight)
        let node = SKSpriteNode(texture: texture, size: tagSize)
        node.name = Self.tagNodeName
        node.physicsBody = {
            let body = SKPhysicsBody(rectangleOf: tagSize)
            body.restitution = bounciness
            body.friction = 0.3
            body.linearDamping = 0.1
            body.angularDamping = 0.3
            body.allowsRotation = true
            body.affectedByGravity = true
            return body
        }()
        return node
    }

    private func renderTagImage(color: PhysicsTagColor) -> UIImage {
        let size = CGSize(width: tagWidth, height: tagHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let capsule = UIBezierPath(roundedRect: rect, cornerRadius: size.height / 2)
            cgCtx.saveGState()
            capsule.addClip()
            color.backgroundColor.setFill()
            UIRectFill(rect)
            cgCtx.restoreGState()

            let dotRect = CGRect(
                x: leftPadding,
                y: (size.height - dotDiameter) / 2,
                width: dotDiameter, height: dotDiameter
            )
            color.foregroundColor.setFill()
            UIBezierPath(ovalIn: dotRect).fill()

            let attr = NSAttributedString(
                string: "example",
                attributes: [.font: Self.tagFont, .foregroundColor: color.foregroundColor]
            )
            let textSize = attr.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin], context: nil
            ).size
            let textOrigin = CGPoint(
                x: leftPadding + dotDiameter + dotTextGap,
                y: (size.height - textSize.height) / 2
            )
            attr.draw(at: textOrigin)
        }
    }
}

// MARK: - Dragging

extension PhysicsTagScene {
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard let touch = touches.first, draggedNode == nil else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location).first { $0.name == Self.tagNodeName } as? SKSpriteNode
        guard let node = tapped else { return }
        node.physicsBody?.isDynamic = false
        node.physicsBody?.velocity = .zero
        node.physicsBody?.angularVelocity = 0
        dragOffset = CGPoint(x: location.x - node.position.x, y: location.y - node.position.y)
        lastDragPosition = node.position
        lastDragTimestamp = touch.timestamp
        draggedNode = node
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard let touch = touches.first, let node = draggedNode else { return }
        let location = touch.location(in: self)
        let newPos = clampedPosition(
            CGPoint(x: location.x - dragOffset.x, y: location.y - dragOffset.y),
            nodeSize: node.size,
            rotation: node.zRotation
        )
        lastDragPosition = node.position
        lastDragTimestamp = touch.timestamp
        node.position = newPos
    }

    override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
        applyThrowVelocity(from: touches.first)
        releaseDraggedNode()
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
        releaseDraggedNode()
    }

    private func applyThrowVelocity(from touch: UITouch?) {
        guard let node = draggedNode, let body = node.physicsBody, let touch else { return }
        let dt = touch.timestamp - lastDragTimestamp
        guard dt > Self.minimumDragDeltaTime else { return }
        var v = CGVector(
            dx: (node.position.x - lastDragPosition.x) / dt,
            dy: (node.position.y - lastDragPosition.y) / dt
        )
        let speed = hypot(v.dx, v.dy)
        if speed > Self.maxThrowSpeed {
            let scale = Self.maxThrowSpeed / speed
            v = CGVector(dx: v.dx * scale, dy: v.dy * scale)
        }
        body.velocity = v
    }

    private func releaseDraggedNode() {
        draggedNode?.physicsBody?.isDynamic = true
        draggedNode = nil
        dragOffset = .zero
        lastDragPosition = .zero
        lastDragTimestamp = 0
    }

    private func clampedPosition(_ position: CGPoint, nodeSize: CGSize, rotation: CGFloat) -> CGPoint {
        let c = abs(cos(rotation))
        let s = abs(sin(rotation))
        let hw = (nodeSize.width * c + nodeSize.height * s) / 2
        let hh = (nodeSize.width * s + nodeSize.height * c) / 2
        let x = min(max(position.x, hw), size.width - hw)
        let y = min(max(position.y, hh), size.height - hh)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Texture cache key

private struct TextureKey: Hashable {
    let color: PhysicsTagColor
    let scale: CGFloat
}

// MARK: - TagColor

enum PhysicsTagColor: CaseIterable {
    case red, pink, orange, yellow, green, mint, blue, indigo, purple, brown

    var hue: CGFloat {
        switch self {
        case .red:    0.00
        case .pink:   0.92
        case .orange: 0.08
        case .yellow: 0.13
        case .green:  0.33
        case .mint:   0.47
        case .blue:   0.58
        case .indigo: 0.70
        case .purple: 0.78
        case .brown:  0.07
        }
    }

    var foregroundColor: UIColor { UIColor(hue: hue, saturation: 0.7, brightness: 0.8, alpha: 1.0) }
    var backgroundColor: UIColor { UIColor(hue: hue, saturation: 0.15, brightness: 1.0, alpha: 0.2) }
}

// MARK: - Preview

#Preview { NavigationStack { PhysicsTagView() } }
