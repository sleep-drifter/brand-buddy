// OscillaFluidView.swift — Oscilla Lab v0.2
//
// THE stateful layer of the synth. Every other Oscilla engine is a pure
// shader fold: OscillaEval resolves [layer][param] values each frame and
// OscillaRenderer re-derives the whole picture from them, so nothing
// persists. The ink-fluid engine is different in kind — a GPU Navier–Stokes
// solver whose textures ACCUMULATE (what you put down, stays) — so its state
// lives here, on the Coordinator behind an MTKView, never in the model, the
// eval, or the renderer.
//
// The boundary with the pure eval: the lab pushes plain VALUES in — the
// normalized [flow, brush, fade, swirl] slice from OscillaEval.layerParams,
// the latest brush sample, and Drop/Rinse fire Dates consumed as EDGE
// triggers (`.distantPast` = never fired, always ignored) — and nothing
// flows back out. LFO/gate modulation therefore INTEGRATES into the sim (it
// does not revert when the modulator does), which is why the factory fences
// modulation depths low on this engine.
//
// A trimmed ink-mode clone of the shipped MetalStableFluidView
// (More/Playgrounds/StableFluidView.swift): the same device/queue/heap/
// texture/PSO setup and per-frame compute sequence, minus the obstacle pass
// and the non-sumi display modes, plus the appended fluidDrop / fluidClear /
// fluidSumiFS stages in StableFluidKernels.metal. The stable-fluid chain is
// MIT end-to-end (Jos Stam's algorithm; TypeGPU © 2025 Software Mansion;
// my-toybox © 2025 takehito) — full notices in THIRD_PARTY_LICENSES.md at
// the repo root.

import Metal
import MetalKit
import SwiftUI
import UIKit

/// The lab's latest drag sample, in view-point space. `last` is the previous
/// sample's location (nil on the first sample of a stroke — the coordinator
/// maps nil to delta ZERO, so a stroke never starts with a corner-to-finger
/// ink jet).
struct OscillaFluidBrush: Equatable {
    var location: CGPoint
    var last: CGPoint?
    var isDown: Bool
}

/// One Drop gate fire, derived from perf.gateFires. `fired` is the edge the
/// coordinator latches on; `level` drives pad glow only — A DROP IS A DROP,
/// the splash itself is always full strength. `point` is the tapPoint
/// (nil = grid center).
struct OscillaFluidDrop: Equatable {
    var fired: Date
    var level: Float
    var point: CGPoint?
}

/// The live stable-fluid surface. Value inputs only — NO @Binding, NO shared
/// observable; updateUIView copies each SwiftUI frame's values onto the
/// Coordinator and the MTKView keeps its own display-link clock (expected
/// ≤1 frame latency). The renderer always wraps this view in `.id(patch.id)`
/// so a patch switch tears down the Metal heap.
struct OscillaFluidView: UIViewRepresentable {
    var params: [Float]        // eval'd normalized [flow, brush, fade, swirl]
    var brush: OscillaFluidBrush
    var drop: OscillaFluidDrop
    var rinse: Date            // last Rinse fire; coordinator clears textures on edge

    func makeCoordinator() -> Coordinator {
        let device = MTLCreateSystemDefaultDevice()!
        return Coordinator(device: device)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.framebufferOnly = true
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator
        if params.count >= 4 {          // else keep the previous physicals
            coordinator.latestParams = params
        }
        coordinator.latestBrush = brush
        coordinator.enqueueDropIfNew(drop)
        coordinator.enqueueRinseIfNew(rinse)
    }

    // MARK: - Coordinator

    /// Owns the Metal stack and ALL simulation state. updateUIView cannot
    /// encode GPU work, so Drop/Rinse edges are latched here as pending flags
    /// and consumed by draw(in:) at the top of the simulation encode.
    @MainActor
    final class Coordinator: NSObject, MTKViewDelegate {
        struct SimParamsBuffer { var deltaTime: Float; var viscosity: Float; var inkFade: Float; var vorticity: Float }
        struct BrushParamsBuffer {
            var pos: SIMD2<Int32>
            var delta: SIMD2<Float>
            var radius: Float
            var forceScale: Float
            var inkAmount: Float
        }

        /// Fixed physicals — the knobs control the water (deltaTime, brush
        /// radius, fade, swirl); everything else is the patch's identity.
        private enum FluidConstants {
            static let gridSize = 256
            static let viscosity: Float = 1e-4
            static let jacobiIterations = 10
            static let brushForceScale: Float = 1.0
            static let brushInkAmount: Float = 0.02   // shipped playground default
            // A DROP IS A DROP — constant full strength, envelope level ignored.
            static let dropForceScale: Float = 0.9
            static let dropInkAmount: Float = 0.05
            static let dropRadiusFraction: Float = 0.09
        }

        let device: any MTLDevice
        private let queue: any MTLCommandQueue
        private let linearSampler: any MTLSamplerState

        private var brushPSO: (any MTLComputePipelineState)!
        private var dropPSO: (any MTLComputePipelineState)!
        private var clearPSO: (any MTLComputePipelineState)!
        private var addInkPSO: (any MTLComputePipelineState)!
        private var addForcesPSO: (any MTLComputePipelineState)!
        private var advectPSO: (any MTLComputePipelineState)!
        private var diffusionPSO: (any MTLComputePipelineState)!
        private var divergencePSO: (any MTLComputePipelineState)!
        private var pressurePSO: (any MTLComputePipelineState)!
        private var projectPSO: (any MTLComputePipelineState)!
        private var curlPSO: (any MTLComputePipelineState)!
        private var vorticityPSO: (any MTLComputePipelineState)!
        private var advectInkPSO: (any MTLComputePipelineState)!

        private var sumiRenderPSO: (any MTLRenderPipelineState)!

        private var velTex: [any MTLTexture] = []
        private var inkTex: [any MTLTexture] = []
        private var pressureTex: [any MTLTexture] = []
        private var forceTex: (any MTLTexture)!
        private var newInkTex: (any MTLTexture)!
        private var divergenceTex: (any MTLTexture)!
        private var curlTex: (any MTLTexture)!
        private var simulationHeap: (any MTLHeap)?

        private var velIndex = 0
        private var inkIndex = 0
        private var pressureIndex = 0

        // Live inputs, pushed by updateUIView. latestParams starts neutral and
        // is guaranteed count >= 4 (pushes are guarded).
        var latestParams: [Float] = [0.5, 0.35, 0.0, 0.0]
        var latestBrush = OscillaFluidBrush(location: .zero, last: nil, isDown: false)

        // EDGE DETECTION state lives HERE (the representable struct is
        // recreated every frame). Initialized .distantPast; an incoming
        // .distantPast is ignored, so coordinator re-creation on patch switch
        // (`.id(patch.id)`) is splash-free for free.
        private var lastSeenDrop = Date.distantPast
        private var lastSeenRinse = Date.distantPast
        private var pendingDrop: OscillaFluidDrop?
        private var pendingRinse = false

        init(device: any MTLDevice) {
            self.device = device
            self.queue = device.makeCommandQueue()!

            let samplerDesc = MTLSamplerDescriptor()
            samplerDesc.minFilter = .linear
            samplerDesc.magFilter = .linear
            samplerDesc.sAddressMode = .clampToEdge
            samplerDesc.tAddressMode = .clampToEdge
            self.linearSampler = device.makeSamplerState(descriptor: samplerDesc)!

            super.init()
            buildPipelines()
            makeTextures(size: FluidConstants.gridSize)
            clearAllSimTextures()
        }

        // MARK: Pipelines + textures (clone of the shipped setup)

        private func buildPipelines() {
            let library = device.makeDefaultLibrary()!

            func computePSO(_ name: String) -> any MTLComputePipelineState {
                let fn = library.makeFunction(name: name)!
                let desc = MTLComputePipelineDescriptor()
                desc.computeFunction = fn
                desc.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
                return try! device.makeComputePipelineState(descriptor: desc, options: [], reflection: nil)
            }

            brushPSO = computePSO("fluidBrush")
            dropPSO = computePSO("fluidDrop")
            clearPSO = computePSO("fluidClear")
            addInkPSO = computePSO("fluidAddInk")
            addForcesPSO = computePSO("fluidAddForces")
            advectPSO = computePSO("fluidAdvect")
            diffusionPSO = computePSO("fluidDiffusion")
            divergencePSO = computePSO("fluidDivergence")
            pressurePSO = computePSO("fluidPressure")
            projectPSO = computePSO("fluidProject")
            curlPSO = computePSO("fluidCurl")
            vorticityPSO = computePSO("fluidVorticity")
            advectInkPSO = computePSO("fluidAdvectInk")

            let vs = library.makeFunction(name: "fluidFullscreenVS")!
            let fs = library.makeFunction(name: "fluidSumiFS")!
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = vs
            desc.fragmentFunction = fs
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            sumiRenderPSO = try! device.makeRenderPipelineState(descriptor: desc)
        }

        private func makeTextures(size: Int) {
            let texDesc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba16Float, width: size, height: size, mipmapped: false
            )
            texDesc.usage = [.shaderRead, .shaderWrite]
            texDesc.storageMode = .private

            let texCount = 10
            let sizeAndAlign = device.heapTextureSizeAndAlign(descriptor: texDesc)
            let alignedSize = (sizeAndAlign.size + sizeAndAlign.align - 1) & ~(sizeAndAlign.align - 1)

            let heapDesc = MTLHeapDescriptor()
            heapDesc.size = alignedSize * texCount
            heapDesc.storageMode = .private
            heapDesc.hazardTrackingMode = .tracked

            if let heap = device.makeHeap(descriptor: heapDesc) {
                simulationHeap = heap
                func heapTexture() -> any MTLTexture { heap.makeTexture(descriptor: texDesc)! }
                velTex = [heapTexture(), heapTexture()]
                inkTex = [heapTexture(), heapTexture()]
                pressureTex = [heapTexture(), heapTexture()]
                forceTex = heapTexture()
                newInkTex = heapTexture()
                divergenceTex = heapTexture()
                curlTex = heapTexture()
            } else {
                simulationHeap = nil
                func deviceTexture() -> any MTLTexture { device.makeTexture(descriptor: texDesc)! }
                velTex = [deviceTexture(), deviceTexture()]
                inkTex = [deviceTexture(), deviceTexture()]
                pressureTex = [deviceTexture(), deviceTexture()]
                forceTex = deviceTexture()
                newInkTex = deviceTexture()
                divergenceTex = deviceTexture()
                curlTex = deviceTexture()
            }

            velIndex = 0
            inkIndex = 0
            pressureIndex = 0
        }

        /// Heap textures come back with UNDEFINED contents (the shipped
        /// playground tolerates that by luck) — run fluidClear over all six
        /// sim-state textures once, right after makeTextures.
        private func clearAllSimTextures() {
            guard let cb = queue.makeCommandBuffer(),
                  let enc = cb.makeComputeCommandEncoder()
            else { return }
            let (numGroups, threadsPerGroup) = Self.threadgroupSizes(gridSize: velTex[0].width)
            encodeClear(enc, numGroups: numGroups, threadsPerGroup: threadsPerGroup)
            enc.endEncoding()
            cb.commit()
        }

        // MARK: Edge latches (updateUIView cannot encode GPU work)

        /// Latch a Drop edge. `.distantPast` (never fired) is always ignored.
        func enqueueDropIfNew(_ drop: OscillaFluidDrop) {
            guard drop.fired != .distantPast, drop.fired != lastSeenDrop else { return }
            lastSeenDrop = drop.fired
            pendingDrop = drop
        }

        /// Latch a Rinse edge. `.distantPast` (never fired) is always ignored.
        func enqueueRinseIfNew(_ rinse: Date) {
            guard rinse != .distantPast, rinse != lastSeenRinse else { return }
            lastSeenRinse = rinse
            pendingRinse = true
        }

        // MARK: MTKViewDelegate

        func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let commandBuffer = queue.makeCommandBuffer()
            else { return }

            encodeSimulation(into: commandBuffer, viewSize: view.bounds.size)
            if let rpd = view.currentRenderPassDescriptor {
                encodeRender(into: commandBuffer, with: rpd)
            }
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        // MARK: Simulation encode (the shipped sequence, minus obstacle)

        private func encodeSimulation(into cb: any MTLCommandBuffer, viewSize: CGSize) {
            guard let enc = cb.makeComputeCommandEncoder() else { return }

            let gridSize = velTex[0].width
            let (numGroups, threadsPerGroup) = Self.threadgroupSizes(gridSize: gridSize)

            // Normalized → physical (contract-pinned mapping).
            let p = latestParams
            var simParams = SimParamsBuffer(
                deltaTime: 0.2 + p[0] * 1.3,
                viscosity: FluidConstants.viscosity,
                inkFade: p[2] * 0.05,
                vorticity: p[3] * 5.0
            )

            // 1. Rinse: consume the latched flag FIRST, before any injection.
            if pendingRinse {
                encodeClear(enc, numGroups: numGroups, threadsPerGroup: threadsPerGroup)
                pendingRinse = false
            }

            // 2. Brush block — a COMPLETE injector → addInk → addForces run.
            if latestBrush.isDown,
               var brushParams = brushInjectionParams(viewSize: viewSize, gridSize: gridSize) {
                encodeInjection(enc, injector: brushPSO, params: &brushParams, sim: &simParams,
                                numGroups: numGroups, threadsPerGroup: threadsPerGroup)
            }

            // 3. Drop block — its own COMPLETE block, never interleaved with
            //    the brush block (each injector overwrites the whole force/ink
            //    textures, so two injectors before one add pass would silently
            //    erase the first exactly when painting and a Drop coincide).
            if let drop = pendingDrop,
               var dropParams = dropInjectionParams(drop, viewSize: viewSize, gridSize: gridSize) {
                encodeInjection(enc, injector: dropPSO, params: &dropParams, sim: &simParams,
                                numGroups: numGroups, threadsPerGroup: threadsPerGroup)
                pendingDrop = nil
            }

            // 4. Advect velocity.
            enc.setComputePipelineState(advectPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(velTex[1 - velIndex], index: 1)
            enc.setSamplerState(linearSampler, index: 0)
            enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            velIndex = 1 - velIndex

            // 5. Diffusion (Jacobi).
            for _ in 0 ..< FluidConstants.jacobiIterations {
                enc.setComputePipelineState(diffusionPSO)
                enc.setTexture(velTex[velIndex], index: 0)
                enc.setTexture(velTex[1 - velIndex], index: 1)
                enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
                velIndex = 1 - velIndex
            }

            // 6. Vorticity confinement, only when the Swirl physical is live.
            if simParams.vorticity > 0 {
                enc.setComputePipelineState(curlPSO)
                enc.setTexture(velTex[velIndex], index: 0)
                enc.setTexture(curlTex, index: 1)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)

                enc.setComputePipelineState(vorticityPSO)
                enc.setTexture(velTex[velIndex], index: 0)
                enc.setTexture(curlTex, index: 1)
                enc.setTexture(velTex[1 - velIndex], index: 2)
                enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
                velIndex = 1 - velIndex
            }

            // 7. Divergence.
            enc.setComputePipelineState(divergencePSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(divergenceTex, index: 1)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)

            // 8. Pressure solve — pressureIndex resets to 0 EVERY frame
            //    (warm start from last frame's field, shipped behavior).
            pressureIndex = 0
            for _ in 0 ..< FluidConstants.jacobiIterations {
                enc.setComputePipelineState(pressurePSO)
                enc.setTexture(pressureTex[pressureIndex], index: 0)
                enc.setTexture(divergenceTex, index: 1)
                enc.setTexture(pressureTex[1 - pressureIndex], index: 2)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
                pressureIndex = 1 - pressureIndex
            }

            // 9. Project.
            enc.setComputePipelineState(projectPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(pressureTex[pressureIndex], index: 1)
            enc.setTexture(velTex[1 - velIndex], index: 2)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            velIndex = 1 - velIndex

            // 10. Advect ink.
            enc.setComputePipelineState(advectInkPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(inkTex[inkIndex], index: 1)
            enc.setTexture(inkTex[1 - inkIndex], index: 2)
            enc.setSamplerState(linearSampler, index: 0)
            enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            inkIndex = 1 - inkIndex

            enc.endEncoding()
        }

        /// One COMPLETE injection block: injector kernel → fluidAddInk (flip
        /// inkIndex) → fluidAddForces (flip velIndex). Brush and drop each get
        /// their own call — the injector writes EVERY texel of forceTex/
        /// newInkTex, so the full add pass must run before the next injector.
        private func encodeInjection(
            _ enc: any MTLComputeCommandEncoder,
            injector: any MTLComputePipelineState,
            params: inout BrushParamsBuffer,
            sim: inout SimParamsBuffer,
            numGroups: MTLSize,
            threadsPerGroup: MTLSize
        ) {
            enc.setComputePipelineState(injector)
            enc.setTexture(forceTex, index: 0)
            enc.setTexture(newInkTex, index: 1)
            enc.setBytes(&params, length: MemoryLayout<BrushParamsBuffer>.stride, index: 0)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)

            enc.setComputePipelineState(addInkPSO)
            enc.setTexture(inkTex[inkIndex], index: 0)
            enc.setTexture(newInkTex, index: 1)
            enc.setTexture(inkTex[1 - inkIndex], index: 2)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            inkIndex = 1 - inkIndex

            enc.setComputePipelineState(addForcesPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(forceTex, index: 1)
            enc.setTexture(velTex[1 - velIndex], index: 2)
            enc.setBytes(&sim, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            velIndex = 1 - velIndex
        }

        /// fluidClear over ALL SIX sim-state textures (vel ×2, ink ×2,
        /// pressure ×2 — pressure included, or the warm-started Jacobi field
        /// re-injects ghost velocity via fluidProject for several frames),
        /// then reset every ping-pong index. forceTex, newInkTex,
        /// divergenceTex, curlTex need no clear — fully written by their
        /// producers before any read each frame.
        private func encodeClear(
            _ enc: any MTLComputeCommandEncoder,
            numGroups: MTLSize,
            threadsPerGroup: MTLSize
        ) {
            enc.setComputePipelineState(clearPSO)
            let targets: [any MTLTexture] = [
                velTex[0], velTex[1],
                inkTex[0], inkTex[1],
                pressureTex[0], pressureTex[1],
            ]
            for texture in targets {
                enc.setTexture(texture, index: 0)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            }
            velIndex = 0
            inkIndex = 0
            pressureIndex = 0
        }

        // MARK: Render encode (sumi-e only)

        private func encodeRender(into cb: any MTLCommandBuffer, with rpd: MTLRenderPassDescriptor) {
            guard let enc = cb.makeRenderCommandEncoder(descriptor: rpd) else { return }
            enc.setRenderPipelineState(sumiRenderPSO)
            enc.setFragmentTexture(inkTex[inkIndex], index: 0)
            enc.setFragmentSamplerState(linearSampler, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }

        // MARK: Touch → grid mapping (shipped brushGesture semantics)

        /// Brush params for this frame, or nil before layout (zero view size).
        /// gx = x/w·grid, gy = (1 − y/h)·grid (Y-flip); delta in grid units
        /// per gesture sample; a nil `last` maps to delta ZERO.
        private func brushInjectionParams(viewSize: CGSize, gridSize: Int) -> BrushParamsBuffer? {
            guard viewSize.width > 0, viewSize.height > 0 else { return nil }
            let gridN = Float(gridSize)
            let x = Float(latestBrush.location.x / viewSize.width) * gridN
            let y = Float(1.0 - latestBrush.location.y / viewSize.height) * gridN
            var delta = SIMD2<Float>(0, 0)
            if let last = latestBrush.last {
                let lastX = Float(last.x / viewSize.width) * gridN
                let lastY = Float(1.0 - last.y / viewSize.height) * gridN
                delta = SIMD2<Float>(x - lastX, y - lastY)
            }
            let radiusFraction = 0.02 + latestParams[1] * 0.18
            return BrushParamsBuffer(
                pos: SIMD2<Int32>(Int32(x), Int32(y)),
                delta: delta,
                radius: gridN * radiusFraction,
                forceScale: FluidConstants.brushForceScale,
                inkAmount: FluidConstants.brushInkAmount
            )
        }

        /// Drop params: tapPoint maps exactly like the brush (Y-flip), nil
        /// point = grid center. A DROP IS A DROP — constant full strength;
        /// `drop.level` drives pad glow only, never the ink. Returns nil only
        /// when a tapPoint arrives before layout, in which case the drop
        /// stays pending for the next frame.
        private func dropInjectionParams(
            _ drop: OscillaFluidDrop, viewSize: CGSize, gridSize: Int
        ) -> BrushParamsBuffer? {
            let gridN = Float(gridSize)
            var pos = SIMD2<Int32>(Int32(gridN / 2), Int32(gridN / 2))
            if let point = drop.point {
                guard viewSize.width > 0, viewSize.height > 0 else { return nil }
                let x = Float(point.x / viewSize.width) * gridN
                let y = Float(1.0 - point.y / viewSize.height) * gridN
                pos = SIMD2<Int32>(Int32(x), Int32(y))
            }
            return BrushParamsBuffer(
                pos: pos,
                delta: .zero,
                radius: gridN * FluidConstants.dropRadiusFraction,
                forceScale: FluidConstants.dropForceScale,
                inkAmount: FluidConstants.dropInkAmount
            )
        }

        // MARK: Dispatch geometry

        private static func threadgroupSizes(gridSize: Int) -> (groups: MTLSize, threads: MTLSize) {
            let threadW = 16, threadH = 16
            let threads = MTLSize(width: threadW, height: threadH, depth: 1)
            let groups = MTLSize(
                width: (gridSize + threadW - 1) / threadW,
                height: (gridSize + threadH - 1) / threadH,
                depth: 1
            )
            return (groups, threads)
        }
    }
}
