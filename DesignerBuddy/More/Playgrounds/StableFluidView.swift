import Metal
import MetalKit
import Observation
import simd
import SwiftUI
import UIKit

// Stable-fluid simulation ported from Koshimizu-Takehito's my-toybox.
// A GPU Navier–Stokes solver (Jos Stam, SIGGRAPH 1999): nine compute kernels
// plus render shaders in StableFluidKernels.metal, driven by an MTKView loop.
// The original's cross-platform wrapper is replaced with a UIViewRepresentable,
// the SPM metallib load with makeDefaultLibrary(), and the "waterwheel" asset
// with the app's PreviewBackground.

// MARK: - Model

enum StableFluidDisplayMode: String, CaseIterable {
    case image, ink, velocity, cool
}

enum StableFluidImageContentMode: String, CaseIterable {
    case aspectFit, aspectFill
}

enum StableFluidCoolSource: String, CaseIterable {
    case ink, field
}

enum StableFluidPalette: String, CaseIterable {
    case cool, sunset, mono, neon

    var ink: Color {
        switch self {
        case .cool: Color(red: 0.55, green: 0.88, blue: 1.0)
        case .sunset: Color(red: 1.0, green: 0.62, blue: 0.30)
        case .mono: .white
        case .neon: Color(red: 0.30, green: 1.0, blue: 0.50)
        }
    }

    var background: Color {
        switch self {
        case .cool, .mono: .black
        case .sunset: Color(red: 0.09, green: 0.04, blue: 0.14)
        case .neon: Color(red: 0.02, green: 0.02, blue: 0.05)
        }
    }

    var anchors: (Color, Color, Color, Color) {
        switch self {
        case .cool: (
            Color(red: 0.204, green: 0.780, blue: 0.349),
            Color(red: 0.200, green: 0.830, blue: 0.930),
            Color(red: 0.000, green: 0.478, blue: 1.000),
            Color(red: 0.720, green: 0.620, blue: 0.980)
        )
        case .sunset: (
            Color(red: 1.00, green: 0.35, blue: 0.55),
            Color(red: 1.00, green: 0.58, blue: 0.20),
            Color(red: 0.55, green: 0.30, blue: 0.85),
            Color(red: 1.00, green: 0.80, blue: 0.40)
        )
        case .mono: (
            Color(red: 0.25, green: 0.25, blue: 0.25),
            Color(red: 0.85, green: 0.85, blue: 0.85),
            Color(red: 0.55, green: 0.55, blue: 0.55),
            .white
        )
        case .neon: (
            Color(red: 1.00, green: 0.10, blue: 0.80),
            Color(red: 0.10, green: 0.50, blue: 1.00),
            Color(red: 0.40, green: 1.00, blue: 0.20),
            Color(red: 0.00, green: 1.00, blue: 1.00)
        )
        }
    }

    var glow: Float {
        switch self {
        case .cool: 0.35
        case .sunset: 0.3
        case .mono: 0.15
        case .neon: 0.5
        }
    }
}

struct BrushState {
    var pos: SIMD2<Int32> = .zero
    var delta: SIMD2<Float> = .zero
    var isDown: Bool = false
}

@MainActor
@Observable
final class StableFluidViewModel {
    var deltaTime: Float = 1.0
    var viscosity: Float = 0.0001
    var jacobiIterations: Int = 10
    var displayMode: StableFluidDisplayMode = .image
    var imageContentMode: StableFluidImageContentMode = .aspectFit
    var coolSource: StableFluidCoolSource = .ink
    var coolGlow: Float = 0.35
    var inkExposure: Float = 3.0
    var brushRadiusFraction: Float = 1.0 / 16.0
    var brushInkAmount: Float = 0.02
    var inkFade: Float = 0.0
    var vorticityStrength: Float = 0.0
    var palette: StableFluidPalette = .cool
    var inkColor: Color = StableFluidPalette.cool.ink
    var backgroundColor: Color = StableFluidPalette.cool.background
    var coolAnchorA: Color = StableFluidPalette.cool.anchors.0
    var coolAnchorB: Color = StableFluidPalette.cool.anchors.1
    var coolAnchorC: Color = StableFluidPalette.cool.anchors.2
    var coolAnchorD: Color = StableFluidPalette.cool.anchors.3

    func apply(_ palette: StableFluidPalette) {
        inkColor = palette.ink
        backgroundColor = palette.background
        (coolAnchorA, coolAnchorB, coolAnchorC, coolAnchorD) = palette.anchors
        coolGlow = palette.glow
    }
    var paused: Bool = false
    var gridSize: Int = 256

    var brush = BrushState()
    @ObservationIgnored var lastDragLocation: CGPoint?
    @ObservationIgnored var onGridSizeChanged: ((Int) -> Void)?

    func notifyGridSizeChanged() { onGridSizeChanged?(gridSize) }
}

private extension Color {
    var rgbSIMD3: SIMD3<Float> {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }
}

// MARK: - Metal view

struct MetalStableFluidView: UIViewRepresentable {
    let viewModel: StableFluidViewModel

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
        struct ImageParamsBuffer { var pixelStep: Float; var imageAspect: Float }
        struct CoolParamsBuffer {
            var glow: Float
            var exposure: Float
            var backgroundColor: SIMD3<Float>
            var anchorA: SIMD3<Float>
            var anchorB: SIMD3<Float>
            var anchorC: SIMD3<Float>
            var anchorD: SIMD3<Float>
        }
        struct InkParamsBuffer { var inkColor: SIMD3<Float>; var backgroundColor: SIMD3<Float> }

        private enum BrushDefaults {
            static let forceScale: Float = 1.0
        }

        private let viewModel: StableFluidViewModel
        let device: any MTLDevice
        private let queue: any MTLCommandQueue
        private let linearSampler: any MTLSamplerState

        private var brushPSO: (any MTLComputePipelineState)!
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

        private var inkRenderPSO: (any MTLRenderPipelineState)!
        private var velRenderPSO: (any MTLRenderPipelineState)!
        private var velCoolRenderPSO: (any MTLRenderPipelineState)!
        private var inkCoolRenderPSO: (any MTLRenderPipelineState)!
        private var imageFitRenderPSO: (any MTLRenderPipelineState)!
        private var imageFillRenderPSO: (any MTLRenderPipelineState)!

        private var backgroundTex: (any MTLTexture)?

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

        init(viewModel: StableFluidViewModel, device: any MTLDevice) {
            self.viewModel = viewModel
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
            loadBackgroundTexture()
            makeTextures(size: viewModel.gridSize)

            viewModel.onGridSizeChanged = { [weak self] newSize in
                self?.makeTextures(size: newSize)
            }
        }

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

            func renderPSO(_ fsName: String) -> any MTLRenderPipelineState {
                let fs = library.makeFunction(name: fsName)!
                let desc = MTLRenderPipelineDescriptor()
                desc.vertexFunction = vs
                desc.fragmentFunction = fs
                desc.colorAttachments[0].pixelFormat = .bgra8Unorm
                return try! device.makeRenderPipelineState(descriptor: desc)
            }

            inkRenderPSO = renderPSO("fluidInkFS")
            velRenderPSO = renderPSO("fluidVelocityFS")
            velCoolRenderPSO = renderPSO("fluidVelocityCoolFS")
            inkCoolRenderPSO = renderPSO("fluidInkCoolFS")

            func imageRenderPSO(fill: Bool) -> any MTLRenderPipelineState {
                let fcv = MTLFunctionConstantValues()
                var flag = fill
                fcv.setConstantValue(&flag, type: .bool, index: 0)
                let fs = try! library.makeFunction(name: "fluidImageFS", constantValues: fcv)
                let desc = MTLRenderPipelineDescriptor()
                desc.vertexFunction = vs
                desc.fragmentFunction = fs
                desc.colorAttachments[0].pixelFormat = .bgra8Unorm
                return try! device.makeRenderPipelineState(descriptor: desc)
            }
            imageFitRenderPSO = imageRenderPSO(fill: false)
            imageFillRenderPSO = imageRenderPSO(fill: true)
        }

        private func loadBackgroundTexture() {
            guard let cgImage = UIImage(named: "PreviewBackground")?.cgImage else { return }
            let loader = MTKTextureLoader(device: device)
            backgroundTex = try? loader.newTexture(cgImage: cgImage, options: [
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .SRGB: false,
            ])
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

        func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let commandBuffer = queue.makeCommandBuffer()
            else { return }

            let gridSize = velTex[0].width
            if !viewModel.paused {
                encodeSimulation(into: commandBuffer, gridSize: gridSize)
            }
            if let rpd = view.currentRenderPassDescriptor {
                encodeRender(into: commandBuffer, with: rpd)
            }
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func encodeSimulation(into cb: any MTLCommandBuffer, gridSize: Int) {
            guard let enc = cb.makeComputeCommandEncoder() else { return }

            let threadW = 16, threadH = 16
            let threadsPerGroup = MTLSize(width: threadW, height: threadH, depth: 1)
            let numGroups = MTLSize(
                width: (gridSize + threadW - 1) / threadW,
                height: (gridSize + threadH - 1) / threadH,
                depth: 1
            )

            var simParams = SimParamsBuffer(
                deltaTime: viewModel.deltaTime,
                viscosity: viewModel.viscosity,
                inkFade: viewModel.inkFade,
                vorticity: viewModel.vorticityStrength
            )

            if viewModel.brush.isDown {
                var brushParams = BrushParamsBuffer(
                    pos: viewModel.brush.pos,
                    delta: viewModel.brush.delta,
                    radius: Float(gridSize) * viewModel.brushRadiusFraction,
                    forceScale: BrushDefaults.forceScale,
                    inkAmount: viewModel.brushInkAmount
                )
                enc.setComputePipelineState(brushPSO)
                enc.setTexture(forceTex, index: 0)
                enc.setTexture(newInkTex, index: 1)
                enc.setBytes(&brushParams, length: MemoryLayout<BrushParamsBuffer>.stride, index: 0)
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
                enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
                velIndex = 1 - velIndex
            }

            enc.setComputePipelineState(advectPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(velTex[1 - velIndex], index: 1)
            enc.setSamplerState(linearSampler, index: 0)
            enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            velIndex = 1 - velIndex

            for _ in 0 ..< viewModel.jacobiIterations {
                enc.setComputePipelineState(diffusionPSO)
                enc.setTexture(velTex[velIndex], index: 0)
                enc.setTexture(velTex[1 - velIndex], index: 1)
                enc.setBytes(&simParams, length: MemoryLayout<SimParamsBuffer>.stride, index: 0)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
                velIndex = 1 - velIndex
            }

            if viewModel.vorticityStrength > 0 {
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

            enc.setComputePipelineState(divergencePSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(divergenceTex, index: 1)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)

            pressureIndex = 0
            for _ in 0 ..< viewModel.jacobiIterations {
                enc.setComputePipelineState(pressurePSO)
                enc.setTexture(pressureTex[pressureIndex], index: 0)
                enc.setTexture(divergenceTex, index: 1)
                enc.setTexture(pressureTex[1 - pressureIndex], index: 2)
                enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
                pressureIndex = 1 - pressureIndex
            }

            enc.setComputePipelineState(projectPSO)
            enc.setTexture(velTex[velIndex], index: 0)
            enc.setTexture(pressureTex[pressureIndex], index: 1)
            enc.setTexture(velTex[1 - velIndex], index: 2)
            enc.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
            velIndex = 1 - velIndex

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

        private func encodeRender(into cb: any MTLCommandBuffer, with rpd: MTLRenderPassDescriptor) {
            guard let enc = cb.makeRenderCommandEncoder(descriptor: rpd) else { return }

            switch viewModel.displayMode {
            case .image:
                let pso = viewModel.imageContentMode == .aspectFill
                    ? imageFillRenderPSO! : imageFitRenderPSO!
                enc.setRenderPipelineState(pso)
                enc.setFragmentTexture(inkTex[inkIndex], index: 0)
                enc.setFragmentTexture(backgroundTex, index: 1)
                let bgW = Float(backgroundTex?.width ?? 1)
                let bgH = Float(backgroundTex?.height ?? 1)
                var imageParams = ImageParamsBuffer(
                    pixelStep: 1.0 / Float(velTex[0].width),
                    imageAspect: bgW / bgH
                )
                enc.setFragmentBytes(&imageParams, length: MemoryLayout<ImageParamsBuffer>.stride, index: 0)
            case .ink:
                enc.setRenderPipelineState(inkRenderPSO)
                enc.setFragmentTexture(inkTex[inkIndex], index: 0)
                var inkParams = InkParamsBuffer(
                    inkColor: viewModel.inkColor.rgbSIMD3,
                    backgroundColor: viewModel.backgroundColor.rgbSIMD3
                )
                enc.setFragmentBytes(&inkParams, length: MemoryLayout<InkParamsBuffer>.stride, index: 0)
            case .velocity:
                enc.setRenderPipelineState(velRenderPSO)
                enc.setFragmentTexture(velTex[velIndex], index: 0)
            case .cool:
                var coolParams = CoolParamsBuffer(
                    glow: viewModel.coolGlow,
                    exposure: viewModel.inkExposure,
                    backgroundColor: viewModel.backgroundColor.rgbSIMD3,
                    anchorA: viewModel.coolAnchorA.rgbSIMD3,
                    anchorB: viewModel.coolAnchorB.rgbSIMD3,
                    anchorC: viewModel.coolAnchorC.rgbSIMD3,
                    anchorD: viewModel.coolAnchorD.rgbSIMD3
                )
                switch viewModel.coolSource {
                case .ink:
                    enc.setRenderPipelineState(inkCoolRenderPSO)
                    enc.setFragmentTexture(velTex[velIndex], index: 0)
                    enc.setFragmentTexture(inkTex[inkIndex], index: 1)
                case .field:
                    enc.setRenderPipelineState(velCoolRenderPSO)
                    enc.setFragmentTexture(velTex[velIndex], index: 0)
                }
                enc.setFragmentBytes(&coolParams, length: MemoryLayout<CoolParamsBuffer>.stride, index: 0)
            }
            enc.setFragmentSamplerState(linearSampler, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }
    }

    func makeCoordinator() -> Coordinator {
        let device = MTLCreateSystemDefaultDevice()!
        return Coordinator(viewModel: viewModel, device: device)
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

    func updateUIView(_: MTKView, context _: Context) {}
}

// MARK: - Screen

struct StableFluidView: View {
    @State private var viewModel = StableFluidViewModel()

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                MetalStableFluidView(viewModel: viewModel)
                    .gesture(brushGesture(size: geometry.size))
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            ScrollView {
                controls
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .tint(.blue)
        .navigationTitle("Stable Fluid")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func brushGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let gridN = Float(viewModel.gridSize)
                let x = Float(value.location.x / size.width) * gridN
                let y = Float(1.0 - value.location.y / size.height) * gridN
                if let lastLoc = viewModel.lastDragLocation {
                    let lastX = Float(lastLoc.x / size.width) * gridN
                    let lastY = Float(1.0 - lastLoc.y / size.height) * gridN
                    viewModel.brush.delta = SIMD2<Float>(x - lastX, y - lastY)
                } else {
                    viewModel.brush.delta = .zero
                }
                viewModel.brush.pos = SIMD2<Int32>(Int32(x), Int32(y))
                viewModel.brush.isDown = true
                viewModel.lastDragLocation = value.location
            }
            .onEnded { _ in
                viewModel.brush.isDown = false
                viewModel.brush.delta = .zero
                viewModel.lastDragLocation = nil
            }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Display").font(.subheadline.weight(.semibold))
                Picker("Display", selection: $viewModel.displayMode) {
                    ForEach(StableFluidDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            if viewModel.displayMode == .image {
                HStack {
                    Text("Image").font(.subheadline.weight(.semibold))
                    Picker("Image", selection: $viewModel.imageContentMode) {
                        Text("Fit").tag(StableFluidImageContentMode.aspectFit)
                        Text("Fill").tag(StableFluidImageContentMode.aspectFill)
                    }
                    .pickerStyle(.segmented)
                }
            }

            if viewModel.displayMode == .ink || viewModel.displayMode == .cool {
                HStack {
                    Text("Palette").font(.subheadline.weight(.semibold))
                    Picker("Palette", selection: $viewModel.palette) {
                        ForEach(StableFluidPalette.allCases, id: \.self) { palette in
                            Text(palette.rawValue.capitalized).tag(palette)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: viewModel.palette) { _, newValue in
                    viewModel.apply(newValue)
                }
            }

            if viewModel.displayMode == .cool {
                HStack {
                    Text("Source").font(.subheadline.weight(.semibold))
                    Picker("Source", selection: $viewModel.coolSource) {
                        Text("Ink").tag(StableFluidCoolSource.ink)
                        Text("Field").tag(StableFluidCoolSource.field)
                    }
                    .pickerStyle(.segmented)
                }

                HStack(spacing: 24) {
                    ColorPicker("Anchor A", selection: $viewModel.coolAnchorA, supportsOpacity: false)
                    ColorPicker("Anchor B", selection: $viewModel.coolAnchorB, supportsOpacity: false)
                }
                HStack(spacing: 24) {
                    ColorPicker("Anchor C", selection: $viewModel.coolAnchorC, supportsOpacity: false)
                    ColorPicker("Anchor D", selection: $viewModel.coolAnchorD, supportsOpacity: false)
                }

                LabeledContent {
                    Text("Glow: \(String(format: "%.2f", viewModel.coolGlow))")
                } label: {
                    Slider(value: $viewModel.coolGlow, in: 0 ... 1, step: 0.01)
                }

                if viewModel.coolSource == .ink {
                    LabeledContent {
                        Text("Exposure: \(String(format: "%.1f", viewModel.inkExposure))")
                    } label: {
                        Slider(value: $viewModel.inkExposure, in: 0.5 ... 8, step: 0.1)
                    }
                }
            }

            LabeledContent {
                Text("Brush Size: \(String(format: "%.3f", viewModel.brushRadiusFraction))")
            } label: {
                Slider(value: $viewModel.brushRadiusFraction, in: 0.02 ... 0.2, step: 0.001)
            }

            LabeledContent {
                Text("Ink Amount: \(String(format: "%.3f", viewModel.brushInkAmount))")
            } label: {
                Slider(value: $viewModel.brushInkAmount, in: 0.005 ... 0.08, step: 0.001)
            }

            LabeledContent {
                Text("Ink Fade: \(String(format: "%.3f", viewModel.inkFade))")
            } label: {
                Slider(value: $viewModel.inkFade, in: 0 ... 0.05, step: 0.001)
            }

            LabeledContent {
                Text("Swirl: \(String(format: "%.1f", viewModel.vorticityStrength))")
            } label: {
                Slider(value: $viewModel.vorticityStrength, in: 0 ... 5, step: 0.1)
            }

            if viewModel.displayMode == .ink
                || (viewModel.displayMode == .cool && viewModel.coolSource == .ink) {
                HStack(spacing: 24) {
                    if viewModel.displayMode == .ink {
                        ColorPicker("Ink", selection: $viewModel.inkColor, supportsOpacity: false)
                    }
                    ColorPicker("Background", selection: $viewModel.backgroundColor, supportsOpacity: false)
                }
                .font(.subheadline.weight(.semibold))
            }

            LabeledContent {
                Text("Time Step: \(String(format: "%.2f", viewModel.deltaTime))")
            } label: {
                Slider(value: $viewModel.deltaTime, in: 0.05 ... 2.0, step: 0.01)
            }

            LabeledContent {
                Text("Viscosity: \(String(format: "%.6f", viewModel.viscosity))")
            } label: {
                Slider(value: $viewModel.viscosity, in: 0 ... 0.01, step: 0.000001)
            }

            HStack(spacing: 16) {
                Button {
                    viewModel.paused.toggle()
                } label: {
                    Label(viewModel.paused ? "Resume" : "Pause",
                          systemImage: viewModel.paused ? "play.fill" : "pause.fill")
                }
                Button {
                    viewModel.paused = false
                    viewModel.notifyGridSizeChanged()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.body.weight(.semibold))
        }
        .font(.subheadline.monospacedDigit())
    }
}

// MARK: - Preview

#Preview { NavigationStack { StableFluidView().preferredColorScheme(.dark) } }
