//
//  HandshakeFluidBackground.swift
//
//  A self-contained, ambient GPU fluid background for the Handshake login /
//  home screen. Drop this file and `HandshakeFluidKernels.metal` into the app
//  target — no assets, no packages, no other source files.
//
//  Production usage (static, power-saving defaults):
//      ZStack {
//          HandshakeFluidBackground()
//          LoginContent()
//      }
//
//  Live-tuning usage (debug builds) — share a store with the debug panel:
//      @StateObject private var fluid = HandshakeFluidStore()
//      ...
//      ZStack {
//          HandshakeFluidBackground(store: fluid)
//          LoginContent()
//      }
//      .sheet(isPresented: $showDebug) {
//          HandshakeFluidDebugPanel(store: fluid)   // dial in the values
//      }
//
//  The background animates on its own (slow orbiting currents keep the flow
//  alive), reacts to drags on any exposed area, pauses when off-screen or
//  backgrounded, and is capped to 30 fps by default. All of it is tunable via
//  `HandshakeFluidConfig` / the debug panel.
//
//  Requires iOS 14+ and a Metal-capable device; falls back to a static
//  gradient (same palette) where Metal is unavailable.
//

import Combine
import MetalKit
import QuartzCore
import SwiftUI
import simd
import UIKit

// MARK: - Configuration

/// Look-and-feel + performance knobs. Defaults reproduce the cool Handshake
/// login treatment at a battery-friendly 30 fps.
public struct HandshakeFluidConfig: Equatable {
    // Flow-direction palette (the four corners of the direction gradient).
    public var anchorA: Color = Color(red: 0.204, green: 0.780, blue: 0.349)
    public var anchorB: Color = Color(red: 0.200, green: 0.830, blue: 0.930)
    public var anchorC: Color = Color(red: 0.000, green: 0.478, blue: 1.000)
    public var anchorD: Color = Color(red: 0.720, green: 0.620, blue: 0.980)

    /// How strongly fast flow lifts toward icy white (0…1).
    public var glow: Float = 0.15
    /// Extra edge blur, in points, applied by SwiftUI. 0 = crisp.
    public var soften: CGFloat = 1.0
    /// Zoom-in factor that hides the simulation's static border. 1.0 = none.
    public var overscan: Float = 1.04

    /// Show the frosted Handshake "H" mark the fluid flows around.
    public var showLogo: Bool = true
    /// Half-height of the "H" in normalized field space (~0.10 is subtle).
    public var logoScale: Float = 0.11
    /// Italic lean of the "H".
    public var logoSlant: Float = 0.16
    /// Strength of the frosted mark (0…1).
    public var logoStrength: Float = 0.55
    /// Mark centre in normalized field space (0.5, 0.5 = middle).
    public var logoCenter: SIMD2<Float> = SIMD2(0.5, 0.5)

    /// Enable drag-to-stir on exposed background.
    public var interactive: Bool = true

    // Simulation tuning.
    public var deltaTime: Float = 0.30
    public var ambientStrength: Float = 0.60
    public var ambientDecay: Float = 0.995
    public var viscosity: Float = 0.0
    public var vorticity: Float = 0.0

    // Performance.
    /// Render loop cap in frames/sec. 30 is a good ambient-background budget;
    /// note that lowering fps also slows real-time flow (raise `deltaTime` to
    /// compensate).
    public var frameRateCap: Int = 30
    /// Jacobi iterations for the pressure solve. 10–12 is plenty for a
    /// background; 18 is smoother but costs more GPU.
    public var solverIterations: Int = 12
    /// Simulation grid resolution (square). 256 = crisp, 128 = ~4× cheaper.
    public var gridSize: Int = 256

    public init() {}
}

// MARK: - Shared store (for live tuning)

/// Observable wrapper so a debug panel and the background can share one live
/// config. In production you don't need this — use `HandshakeFluidBackground()`.
public final class HandshakeFluidStore: ObservableObject {
    @Published public var config: HandshakeFluidConfig
    public init(config: HandshakeFluidConfig = HandshakeFluidConfig()) {
        self.config = config
    }
}

// MARK: - Public view

public struct HandshakeFluidBackground: View {
    @ObservedObject private var store: HandshakeFluidStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = true

    /// Static configuration (production).
    public init(config: HandshakeFluidConfig = HandshakeFluidConfig()) {
        self.store = HandshakeFluidStore(config: config)
    }

    /// Shared store (debug / live tuning).
    public init(store: HandshakeFluidStore) {
        self.store = store
    }

    public var body: some View {
        Group {
            if MTLCreateSystemDefaultDevice() != nil {
                FluidMetalView(store: store, isPaused: !isVisible || scenePhase != .active)
                    .blur(radius: store.config.soften)
            } else {
                fallbackGradient
            }
        }
        .ignoresSafeArea()
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [store.config.anchorC, store.config.anchorB,
                     store.config.anchorA, store.config.anchorD],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color helper

fileprivate extension Color {
    var rgbSIMD3: SIMD3<Float> {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }
}

// MARK: - Metal-backed representable

private struct FluidMetalView: UIViewRepresentable {
    let store: HandshakeFluidStore
    let isPaused: Bool

    func makeCoordinator() -> FluidCoordinator {
        FluidCoordinator(store: store)
    }

    func makeUIView(context: Context) -> MTKView {
        let coordinator = context.coordinator
        let view = MTKView(frame: .zero, device: coordinator.device)
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.framebufferOnly = true
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate = coordinator

        let pan = UIPanGestureRecognizer(target: coordinator,
                                         action: #selector(FluidCoordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        context.coordinator.panRecognizer = pan
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator
        coordinator.store = store
        let cfg = store.config

        uiView.isPaused = isPaused
        uiView.preferredFramesPerSecond = max(1, cfg.frameRateCap)
        coordinator.panRecognizer?.isEnabled = cfg.interactive
        coordinator.updateGridSizeIfNeeded(cfg.gridSize)
    }
}

// MARK: - Simulation + render driver

private final class FluidCoordinator: NSObject, MTKViewDelegate {
    // Layouts mirror the Metal structs in HandshakeFluidKernels.metal.
    private struct SimParams { var deltaTime: Float; var viscosity: Float; var vorticity: Float }
    private struct BrushParams {
        var pos: SIMD2<Int32>; var delta: SIMD2<Float>; var radius: Float; var strength: Float
    }
    private struct AmbientParams { var time: Float; var deltaTime: Float; var strength: Float; var decay: Float }
    private struct ObstacleParams { var center: SIMD2<Float>; var scale: Float; var slant: Float }
    private struct CoolParams {
        var glow: Float
        var viewAspect: Float
        var overscan: Float
        var markStrength: Float
        var anchorA: SIMD3<Float>
        var anchorB: SIMD3<Float>
        var anchorC: SIMD3<Float>
        var anchorD: SIMD3<Float>
        var obstacleCenter: SIMD2<Float>
        var obstacleScale: Float
        var obstacleSlant: Float
        var obstacleEnabled: Float
    }

    private struct Brush {
        var pos: SIMD2<Int32> = .zero
        var delta: SIMD2<Float> = .zero
        var isDown: Bool = false
    }

    let device: any MTLDevice
    var store: HandshakeFluidStore
    weak var panRecognizer: UIPanGestureRecognizer?

    private var config: HandshakeFluidConfig { store.config }

    private let queue: any MTLCommandQueue
    private let sampler: any MTLSamplerState

    private var clearPSO: (any MTLComputePipelineState)!
    private var brushPSO: (any MTLComputePipelineState)!
    private var ambientPSO: (any MTLComputePipelineState)!
    private var advectPSO: (any MTLComputePipelineState)!
    private var diffusionPSO: (any MTLComputePipelineState)!
    private var curlPSO: (any MTLComputePipelineState)!
    private var vorticityPSO: (any MTLComputePipelineState)!
    private var divergencePSO: (any MTLComputePipelineState)!
    private var pressurePSO: (any MTLComputePipelineState)!
    private var projectPSO: (any MTLComputePipelineState)!
    private var obstaclePSO: (any MTLComputePipelineState)!
    private var coolFieldPSO: (any MTLRenderPipelineState)!

    private var velTex: [any MTLTexture] = []
    private var pressureTex: [any MTLTexture] = []
    private var divergenceTex: (any MTLTexture)!
    private var curlTex: (any MTLTexture)!
    private var currentGridSize = 0

    private var velIndex = 0
    private var pressureIndex = 0

    private var brush = Brush()
    private var lastPanLocation: CGPoint?
    private let startTime: CFTimeInterval = CACurrentMediaTime()

    init(store: HandshakeFluidStore) {
        self.store = store
        self.device = MTLCreateSystemDefaultDevice()!
        self.queue = device.makeCommandQueue()!

        let sd = MTLSamplerDescriptor()
        sd.minFilter = .linear
        sd.magFilter = .linear
        sd.sAddressMode = .clampToEdge
        sd.tAddressMode = .clampToEdge
        self.sampler = device.makeSamplerState(descriptor: sd)!

        super.init()
        buildPipelines()
        makeTextures(size: store.config.gridSize)
        clearFields()
    }

    // MARK: Pipelines

    private func buildPipelines() {
        let library = device.makeDefaultLibrary()!

        func compute(_ name: String) -> any MTLComputePipelineState {
            let desc = MTLComputePipelineDescriptor()
            desc.computeFunction = library.makeFunction(name: name)!
            desc.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
            return try! device.makeComputePipelineState(descriptor: desc, options: [], reflection: nil)
        }

        clearPSO = compute("hsFluidClear")
        brushPSO = compute("hsFluidBrush")
        ambientPSO = compute("hsFluidAmbient")
        advectPSO = compute("hsFluidAdvect")
        diffusionPSO = compute("hsFluidDiffusion")
        curlPSO = compute("hsFluidCurl")
        vorticityPSO = compute("hsFluidVorticity")
        divergencePSO = compute("hsFluidDivergence")
        pressurePSO = compute("hsFluidPressure")
        projectPSO = compute("hsFluidProject")
        obstaclePSO = compute("hsFluidObstacleH")

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "hsFluidFullscreenVS")!
        desc.fragmentFunction = library.makeFunction(name: "hsFluidCoolFieldFS")!
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        coolFieldPSO = try! device.makeRenderPipelineState(descriptor: desc)
    }

    // MARK: Textures

    private func makeTextures(size: Int) {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float, width: size, height: size, mipmapped: false
        )
        desc.usage = [.shaderRead, .shaderWrite]
        desc.storageMode = .private

        func tex() -> any MTLTexture { device.makeTexture(descriptor: desc)! }
        velTex = [tex(), tex()]
        pressureTex = [tex(), tex()]
        divergenceTex = tex()
        curlTex = tex()
        velIndex = 0
        pressureIndex = 0
        currentGridSize = size
    }

    /// Rebuild the field textures if the grid size changed (debug panel).
    func updateGridSizeIfNeeded(_ size: Int) {
        guard size != currentGridSize, size >= 32 else { return }
        makeTextures(size: size)
        clearFields()
    }

    /// Private textures start with undefined contents — zero them once so the
    /// first frames aren't garbage.
    private func clearFields() {
        guard let cb = queue.makeCommandBuffer(), let enc = cb.makeComputeCommandEncoder() else { return }
        let g = currentGridSize
        let tpg = MTLSize(width: 16, height: 16, depth: 1)
        let groups = MTLSize(width: (g + 15) / 16, height: (g + 15) / 16, depth: 1)
        enc.setComputePipelineState(clearPSO)
        for t in [velTex[0], velTex[1], pressureTex[0], pressureTex[1], divergenceTex!, curlTex!] {
            enc.setTexture(t, index: 0)
            enc.dispatchThreadgroups(groups, threadsPerThreadgroup: tpg)
        }
        enc.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
    }

    // MARK: MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let cb = queue.makeCommandBuffer() else { return }

        let g = velTex[0].width
        encodeSimulation(into: cb, gridSize: g)
        if let rpd = view.currentRenderPassDescriptor {
            encodeRender(into: cb, rpd: rpd, drawableSize: view.drawableSize)
        }
        cb.present(drawable)
        cb.commit()
    }

    // MARK: Simulation

    private func encodeSimulation(into cb: any MTLCommandBuffer, gridSize g: Int) {
        guard let enc = cb.makeComputeCommandEncoder() else { return }
        let cfg = config

        let tpg = MTLSize(width: 16, height: 16, depth: 1)
        let groups = MTLSize(width: (g + 15) / 16, height: (g + 15) / 16, depth: 1)
        func dispatch() { enc.dispatchThreadgroups(groups, threadsPerThreadgroup: tpg) }

        var sim = SimParams(deltaTime: cfg.deltaTime, viscosity: cfg.viscosity, vorticity: cfg.vorticity)

        // Ambient stir (+ energy decay) — always.
        var amb = AmbientParams(
            time: Float(CACurrentMediaTime() - startTime),
            deltaTime: cfg.deltaTime,
            strength: cfg.ambientStrength,
            decay: cfg.ambientDecay
        )
        enc.setComputePipelineState(ambientPSO)
        enc.setTexture(velTex[velIndex], index: 0)
        enc.setTexture(velTex[1 - velIndex], index: 1)
        enc.setBytes(&amb, length: MemoryLayout<AmbientParams>.stride, index: 0)
        dispatch(); velIndex = 1 - velIndex

        // Touch impulse.
        if brush.isDown {
            var bp = BrushParams(
                pos: brush.pos,
                delta: brush.delta,
                radius: Float(g) * 0.06,
                strength: 0.5
            )
            enc.setComputePipelineState(brushPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(velTex[1 - velIndex], index: 1)
            enc.setBytes(&bp, length: MemoryLayout<BrushParams>.stride, index: 0)
            dispatch(); velIndex = 1 - velIndex
        }

        // Advect velocity.
        enc.setComputePipelineState(advectPSO)
        enc.setTexture(velTex[velIndex], index: 0)
        enc.setTexture(velTex[1 - velIndex], index: 1)
        enc.setSamplerState(sampler, index: 0)
        enc.setBytes(&sim, length: MemoryLayout<SimParams>.stride, index: 0)
        dispatch(); velIndex = 1 - velIndex

        // Diffusion (only when viscous).
        if cfg.viscosity > 0 {
            for _ in 0 ..< cfg.solverIterations {
                enc.setComputePipelineState(diffusionPSO)
                enc.setTexture(velTex[velIndex], index: 0)
                enc.setTexture(velTex[1 - velIndex], index: 1)
                enc.setBytes(&sim, length: MemoryLayout<SimParams>.stride, index: 0)
                dispatch(); velIndex = 1 - velIndex
            }
        }

        // Vorticity confinement (optional).
        if cfg.vorticity > 0 {
            enc.setComputePipelineState(curlPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(curlTex, index: 1)
            dispatch()

            enc.setComputePipelineState(vorticityPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(curlTex, index: 1)
            enc.setTexture(velTex[1 - velIndex], index: 2)
            enc.setBytes(&sim, length: MemoryLayout<SimParams>.stride, index: 0)
            dispatch(); velIndex = 1 - velIndex
        }

        // Divergence.
        enc.setComputePipelineState(divergencePSO)
        enc.setTexture(velTex[velIndex], index: 0)
        enc.setTexture(divergenceTex, index: 1)
        dispatch()

        // Pressure solve (Jacobi; warm-started from last frame).
        pressureIndex = 0
        for _ in 0 ..< cfg.solverIterations {
            enc.setComputePipelineState(pressurePSO)
            enc.setTexture(pressureTex[pressureIndex], index: 0)
            enc.setTexture(divergenceTex, index: 1)
            enc.setTexture(pressureTex[1 - pressureIndex], index: 2)
            dispatch(); pressureIndex = 1 - pressureIndex
        }

        // Project to divergence-free.
        enc.setComputePipelineState(projectPSO)
        enc.setTexture(velTex[velIndex], index: 0)
        enc.setTexture(pressureTex[pressureIndex], index: 1)
        enc.setTexture(velTex[1 - velIndex], index: 2)
        dispatch(); velIndex = 1 - velIndex

        // Obstacle: fluid flows around the "H".
        if cfg.showLogo {
            var ob = ObstacleParams(center: cfg.logoCenter, scale: cfg.logoScale, slant: cfg.logoSlant)
            enc.setComputePipelineState(obstaclePSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(velTex[1 - velIndex], index: 1)
            enc.setBytes(&ob, length: MemoryLayout<ObstacleParams>.stride, index: 0)
            dispatch(); velIndex = 1 - velIndex
        }

        enc.endEncoding()
    }

    // MARK: Render

    private func encodeRender(into cb: any MTLCommandBuffer, rpd: MTLRenderPassDescriptor, drawableSize: CGSize) {
        guard let enc = cb.makeRenderCommandEncoder(descriptor: rpd) else { return }
        let cfg = config

        let aspect = drawableSize.height > 0 ? Float(drawableSize.width / drawableSize.height) : 1
        var cool = CoolParams(
            glow: cfg.glow,
            viewAspect: aspect,
            overscan: cfg.overscan,
            markStrength: cfg.logoStrength,
            anchorA: cfg.anchorA.rgbSIMD3,
            anchorB: cfg.anchorB.rgbSIMD3,
            anchorC: cfg.anchorC.rgbSIMD3,
            anchorD: cfg.anchorD.rgbSIMD3,
            obstacleCenter: cfg.logoCenter,
            obstacleScale: cfg.logoScale,
            obstacleSlant: cfg.logoSlant,
            obstacleEnabled: cfg.showLogo ? 1 : 0
        )

        enc.setRenderPipelineState(coolFieldPSO)
        enc.setFragmentTexture(velTex[velIndex], index: 0)
        enc.setFragmentSamplerState(sampler, index: 0)
        enc.setFragmentBytes(&cool, length: MemoryLayout<CoolParams>.stride, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
    }

    // MARK: Touch

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        let size = view.bounds.size
        guard size.width > 0, size.height > 0 else { return }
        let loc = recognizer.location(in: view)

        switch recognizer.state {
        case .began:
            lastPanLocation = loc
            brush.delta = .zero
            brush.pos = gridPos(from: loc, size: size)
            brush.isDown = true
        case .changed:
            let cur = gridPos(from: loc, size: size)
            if let last = lastPanLocation {
                let lastGrid = gridPos(from: last, size: size)
                brush.delta = SIMD2<Float>(Float(cur.x - lastGrid.x), Float(cur.y - lastGrid.y))
            } else {
                brush.delta = .zero
            }
            brush.pos = cur
            brush.isDown = true
            lastPanLocation = loc
        default:
            brush.isDown = false
            brush.delta = .zero
            lastPanLocation = nil
        }
    }

    /// Map a view-space point to grid coordinates, inverting the fragment's
    /// aspect-fill + overscan remap so the stir lands under the finger.
    private func gridPos(from loc: CGPoint, size: CGSize) -> SIMD2<Int32> {
        let gridN = Float(currentGridSize)
        let aspect = Float(size.width / size.height)
        var u = Float(loc.x / size.width)
        var v = Float(1.0 - loc.y / size.height)   // flip: grid y is up

        if aspect < 1.0 {
            u = (u - 0.5) * aspect + 0.5
        } else {
            v = (v - 0.5) / aspect + 0.5
        }
        let over = max(config.overscan, 1.0)
        u = (u - 0.5) / over + 0.5
        v = (v - 0.5) / over + 0.5

        let gx = Int32((u * gridN).rounded())
        let gy = Int32((v * gridN).rounded())
        return SIMD2<Int32>(
            max(0, min(Int32(currentGridSize - 1), gx)),
            max(0, min(Int32(currentGridSize - 1), gy))
        )
    }
}

// MARK: - Debug tuning panel

/// A live tuning panel for `HandshakeFluidBackground`. Present it in a sheet
/// (a bottom sheet reads well) sharing the same `HandshakeFluidStore` as the
/// background, adjust to taste, then tap **Copy Swift config** to paste the
/// dialed-in values into your production `HandshakeFluidConfig`.
///
/// Wrap this whole view in `#if DEBUG` at the call site so it never ships.
public struct HandshakeFluidDebugPanel: View {
    @ObservedObject private var store: HandshakeFluidStore
    @State private var copied = false

    public init(store: HandshakeFluidStore) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            Form {
                paletteSection
                markSection
                motionSection
                performanceSection
                exportSection
            }
            .navigationTitle("Fluid Tuner")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Sections

    private var paletteSection: some View {
        Section(header: Text("Palette")) {
            ColorPicker("Anchor A", selection: $store.config.anchorA, supportsOpacity: false)
            ColorPicker("Anchor B", selection: $store.config.anchorB, supportsOpacity: false)
            ColorPicker("Anchor C", selection: $store.config.anchorC, supportsOpacity: false)
            ColorPicker("Anchor D", selection: $store.config.anchorD, supportsOpacity: false)
            slider("Glow", floatBinding(\.glow), 0 ... 1)
            slider("Soften", cgFloatBinding(\.soften), 0 ... 12)
            slider("Overscan", floatBinding(\.overscan), 1 ... 1.3)
        }
    }

    private var markSection: some View {
        Section(header: Text("Handshake “H” mark")) {
            Toggle("Show mark", isOn: $store.config.showLogo)
            if store.config.showLogo {
                slider("Size", floatBinding(\.logoScale), 0.04 ... 0.22)
                slider("Slant", floatBinding(\.logoSlant), -0.4 ... 0.4)
                slider("Strength", floatBinding(\.logoStrength), 0 ... 1)
                slider("Center X", Binding(get: { store.config.logoCenter.x },
                                           set: { store.config.logoCenter.x = $0 }), 0 ... 1)
                slider("Center Y", Binding(get: { store.config.logoCenter.y },
                                           set: { store.config.logoCenter.y = $0 }), 0 ... 1)
            }
        }
    }

    private var motionSection: some View {
        Section(header: Text("Motion")) {
            Toggle("Drag to stir", isOn: $store.config.interactive)
            slider("Time Step", floatBinding(\.deltaTime), 0.05 ... 1.5)
            slider("Ambient Strength", floatBinding(\.ambientStrength), 0 ... 3)
            slider("Ambient Decay", floatBinding(\.ambientDecay), 0.95 ... 1.0, decimals: 4)
            slider("Viscosity", floatBinding(\.viscosity), 0 ... 0.01, decimals: 6)
            slider("Swirl", floatBinding(\.vorticity), 0 ... 5, decimals: 1)
        }
    }

    private var performanceSection: some View {
        Section(header: Text("Performance")) {
            Picker("Frame Rate", selection: $store.config.frameRateCap) {
                Text("24").tag(24); Text("30").tag(30); Text("60").tag(60)
            }
            .pickerStyle(.segmented)
            Stepper("Solver Iterations: \(store.config.solverIterations)",
                    value: $store.config.solverIterations, in: 4 ... 30)
            Picker("Grid Size", selection: $store.config.gridSize) {
                Text("128").tag(128); Text("192").tag(192); Text("256").tag(256)
            }
            .pickerStyle(.segmented)
        }
    }

    private var exportSection: some View {
        Section(header: Text("Export")) {
            Button {
                UIPasteboard.general.string = configCode
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Label(copied ? "Copied!" : "Copy Swift config", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            Text(configCode)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    // MARK: Slider helpers

    private func slider(_ title: String, _ value: Binding<Float>, _ range: ClosedRange<Float>,
                        decimals: Int = 2) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.\(decimals)f", value.wrappedValue))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private func slider(_ title: String, _ value: Binding<CGFloat>, _ range: ClosedRange<CGFloat>,
                        decimals: Int = 1) -> some View {
        slider(title,
               Binding(get: { Float(value.wrappedValue) }, set: { value.wrappedValue = CGFloat($0) }),
               Float(range.lowerBound) ... Float(range.upperBound), decimals: decimals)
    }

    private func floatBinding(_ keyPath: WritableKeyPath<HandshakeFluidConfig, Float>) -> Binding<Float> {
        Binding(get: { store.config[keyPath: keyPath] }, set: { store.config[keyPath: keyPath] = $0 })
    }

    private func cgFloatBinding(_ keyPath: WritableKeyPath<HandshakeFluidConfig, CGFloat>) -> Binding<CGFloat> {
        Binding(get: { store.config[keyPath: keyPath] }, set: { store.config[keyPath: keyPath] = $0 })
    }

    // MARK: Config → Swift snippet

    private var configCode: String {
        let c = store.config
        func f(_ x: Float, _ d: Int = 3) -> String { String(format: "%.\(d)f", x) }
        func col(_ name: String, _ color: Color) -> String {
            let v = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            v.getRed(&r, green: &g, blue: &b, alpha: &a)
            return "cfg.\(name) = Color(red: \(f(Float(r))), green: \(f(Float(g))), blue: \(f(Float(b))))"
        }
        return [
            "var cfg = HandshakeFluidConfig()",
            col("anchorA", c.anchorA),
            col("anchorB", c.anchorB),
            col("anchorC", c.anchorC),
            col("anchorD", c.anchorD),
            "cfg.glow = \(f(c.glow))",
            "cfg.soften = \(f(Float(c.soften), 1))",
            "cfg.overscan = \(f(c.overscan))",
            "cfg.showLogo = \(c.showLogo)",
            "cfg.logoScale = \(f(c.logoScale))",
            "cfg.logoSlant = \(f(c.logoSlant))",
            "cfg.logoStrength = \(f(c.logoStrength))",
            "cfg.logoCenter = SIMD2(\(f(c.logoCenter.x)), \(f(c.logoCenter.y)))",
            "cfg.interactive = \(c.interactive)",
            "cfg.deltaTime = \(f(c.deltaTime))",
            "cfg.ambientStrength = \(f(c.ambientStrength))",
            "cfg.ambientDecay = \(f(c.ambientDecay, 4))",
            "cfg.viscosity = \(f(c.viscosity, 6))",
            "cfg.vorticity = \(f(c.vorticity, 1))",
            "cfg.frameRateCap = \(c.frameRateCap)",
            "cfg.solverIterations = \(c.solverIterations)",
            "cfg.gridSize = \(c.gridSize)",
        ].joined(separator: "\n")
    }
}

// MARK: - Preview

#if DEBUG
struct HandshakeFluidBackground_Previews: PreviewProvider {
    struct Demo: View {
        @StateObject private var fluid = HandshakeFluidStore()
        @State private var showDebug = false
        var body: some View {
            ZStack {
                HandshakeFluidBackground(store: fluid)
                VStack {
                    HStack {
                        Spacer()
                        Button { showDebug = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                        }
                        .foregroundColor(.white).padding()
                    }
                    Spacer()
                    Text("Welcome to Handshake")
                        .font(.title2.weight(.semibold)).foregroundColor(.white)
                    Text("Log in")
                        .font(.body.weight(.semibold)).foregroundColor(.black)
                        .padding(.horizontal, 40).padding(.vertical, 14)
                        .background(Capsule().fill(.white)).padding(.bottom, 60)
                }
            }
            .sheet(isPresented: $showDebug) { HandshakeFluidDebugPanel(store: fluid) }
            .preferredColorScheme(.dark)
        }
    }
    static var previews: some View { Demo() }
}
#endif
