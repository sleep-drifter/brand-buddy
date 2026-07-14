//
//  HandshakeFluidBackground.swift
//
//  A self-contained, ambient GPU fluid background for the Handshake login /
//  home screen. Drop this file and `HandshakeFluidKernels.metal` into the app
//  target — no assets, no other dependencies.
//
//  Usage:
//      ZStack {
//          HandshakeFluidBackground()
//              .ignoresSafeArea()
//          LoginContent()
//      }
//
//  The background animates on its own (a set of slow orbiting vortices keep the
//  flow alive) and also reacts to drags on any exposed area. Everything is
//  tunable via `HandshakeFluidConfig`.
//
//  Requires iOS 14+ and a Metal-capable device. On the (rare) device with no
//  Metal support it falls back to a static gradient built from the same colours.
//

import MetalKit
import QuartzCore
import SwiftUI
import simd
import UIKit

// MARK: - Configuration

/// Look-and-feel knobs for ``HandshakeFluidBackground``. The defaults reproduce
/// the cool Handshake login treatment; tweak a value and rebuild to retune.
public struct HandshakeFluidConfig {
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

    // Simulation tuning — the defaults are calm and stable; touch rarely.
    public var deltaTime: Float = 0.20
    public var ambientStrength: Float = 0.60
    public var ambientDecay: Float = 0.995
    public var viscosity: Float = 0.0
    public var vorticity: Float = 0.0
    public var solverIterations: Int = 18
    public var gridSize: Int = 256

    public init() {}
}

// MARK: - Public view

public struct HandshakeFluidBackground: View {
    private let config: HandshakeFluidConfig

    public init(config: HandshakeFluidConfig = HandshakeFluidConfig()) {
        self.config = config
    }

    public var body: some View {
        Group {
            if MTLCreateSystemDefaultDevice() != nil {
                FluidMetalView(config: config)
                    .blur(radius: config.soften)
            } else {
                fallbackGradient
            }
        }
        .ignoresSafeArea()
    }

    /// Shown only when the device has no Metal support (e.g. some simulators).
    private var fallbackGradient: some View {
        LinearGradient(
            colors: [config.anchorC, config.anchorB, config.anchorA, config.anchorD],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color helper

private extension Color {
    var rgbSIMD3: SIMD3<Float> {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }
}

// MARK: - Metal-backed representable

private struct FluidMetalView: UIViewRepresentable {
    let config: HandshakeFluidConfig

    func makeCoordinator() -> FluidCoordinator {
        FluidCoordinator(config: config)
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

        if config.interactive {
            let pan = UIPanGestureRecognizer(target: coordinator,
                                             action: #selector(FluidCoordinator.handlePan(_:)))
            pan.maximumNumberOfTouches = 1
            view.addGestureRecognizer(pan)
        }
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
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
    private let config: HandshakeFluidConfig
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

    private var velIndex = 0
    private var pressureIndex = 0

    private var brush = Brush()
    private var lastPanLocation: CGPoint?
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    init(config: HandshakeFluidConfig) {
        self.config = config
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
        makeTextures(size: config.gridSize)
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
    }

    /// Private textures start with undefined contents — zero them once so the
    /// first frames aren't garbage.
    private func clearFields() {
        guard let cb = queue.makeCommandBuffer(), let enc = cb.makeComputeCommandEncoder() else { return }
        let g = config.gridSize
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

        let tpg = MTLSize(width: 16, height: 16, depth: 1)
        let groups = MTLSize(width: (g + 15) / 16, height: (g + 15) / 16, depth: 1)
        func dispatch() { enc.dispatchThreadgroups(groups, threadsPerThreadgroup: tpg) }

        var sim = SimParams(deltaTime: config.deltaTime, viscosity: config.viscosity, vorticity: config.vorticity)

        // Ambient stir (+ energy decay) — always.
        var amb = AmbientParams(
            time: Float(CACurrentMediaTime() - startTime),
            deltaTime: config.deltaTime,
            strength: config.ambientStrength,
            decay: config.ambientDecay
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
        if config.viscosity > 0 {
            for _ in 0 ..< config.solverIterations {
                enc.setComputePipelineState(diffusionPSO)
                enc.setTexture(velTex[velIndex], index: 0)
                enc.setTexture(velTex[1 - velIndex], index: 1)
                enc.setBytes(&sim, length: MemoryLayout<SimParams>.stride, index: 0)
                dispatch(); velIndex = 1 - velIndex
            }
        }

        // Vorticity confinement (optional).
        if config.vorticity > 0 {
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
        for _ in 0 ..< config.solverIterations {
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
        if config.showLogo {
            var ob = ObstacleParams(center: config.logoCenter, scale: config.logoScale, slant: config.logoSlant)
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

        let aspect = drawableSize.height > 0 ? Float(drawableSize.width / drawableSize.height) : 1
        var cool = CoolParams(
            glow: config.glow,
            viewAspect: aspect,
            overscan: config.overscan,
            markStrength: config.logoStrength,
            anchorA: config.anchorA.rgbSIMD3,
            anchorB: config.anchorB.rgbSIMD3,
            anchorC: config.anchorC.rgbSIMD3,
            anchorD: config.anchorD.rgbSIMD3,
            obstacleCenter: config.logoCenter,
            obstacleScale: config.logoScale,
            obstacleSlant: config.logoSlant,
            obstacleEnabled: config.showLogo ? 1 : 0
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
        let gridN = Float(config.gridSize)
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
            max(0, min(Int32(config.gridSize - 1), gx)),
            max(0, min(Int32(config.gridSize - 1), gy))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct HandshakeFluidBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            HandshakeFluidBackground()
            VStack(spacing: 16) {
                Spacer()
                Text("Welcome to Handshake")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Log in")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(Capsule().fill(.white))
                    .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
