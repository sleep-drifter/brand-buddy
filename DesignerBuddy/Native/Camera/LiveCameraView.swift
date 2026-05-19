import SwiftUI
import AVFoundation

// MARK: - Live Camera View

struct LiveCameraView: View {
    let config: CameraConfig
    @Binding var captures: [UIImage]
    @StateObject private var model: CameraModel

    init(config: CameraConfig, captures: Binding<[UIImage]>) {
        self.config = config
        _captures = captures
        _model = StateObject(wrappedValue: CameraModel(config: config))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if model.isAuthorized {
                cameraContent
            } else {
                permissionCard
            }
        }
        .navigationTitle(config.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            model.checkAuthorization()
            model.setupSession()
        }
        .onChange(of: model.isAuthorized) { _, ok in
            if ok { model.setupSession() }
        }
        .onDisappear {
            model.tearDownSession()
        }
    }

    // MARK: - Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: model.session)
                .ignoresSafeArea()

            overlayLayer
            controlsLayer

            // Captured photo preview / crop view
            if let image = model.capturedImage {
                switch config {
                case .freeCrop:
                    FreeCropView(image: image, captures: $captures) {
                        withAnimation { model.capturedImage = nil }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: model.capturedImage != nil)
                case .circularCrop:
                    CircularCropView(image: image, captures: $captures) {
                        withAnimation { model.capturedImage = nil }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: model.capturedImage != nil)
                default:
                    capturePreview(image: image)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: model.capturedImage != nil)
                }
            }
        }
    }

    // MARK: - Overlay Layer

    @ViewBuilder
    private var overlayLayer: some View {
        switch config {
        case .gridOverlay:
            GridOverlayView()
        case .qrBarcodeScanner:
            QRBoundsOverlay(codes: model.detectedCodes)
        case .faceDetection:
            FaceBoxesOverlay(rects: model.detectedFaces)
        case .liveOCR:
            OCROverlay(boxes: model.recognizedTextBoxes, texts: model.recognizedTextStrings)
        default:
            EmptyView()
        }
    }

    // MARK: - Controls Layer

    @ViewBuilder
    private var controlsLayer: some View {
        switch config {
        case .standardCentered, .backWide, .frontSelfie, .photo, .gridOverlay,
             .faceDetection, .liveOCR, .freeCrop, .circularCrop:
            StandardControlsOverlay(model: model)
        case .minimalScan:
            MinimalScanOverlay(model: model)
        case .qrBarcodeScanner:
            MinimalScanOverlay(model: model, showShutter: false)
        case .floatingSocial:
            FloatingSocialOverlay(model: model)
        case .video:
            VideoControlsOverlay(model: model)
        case .flashControl:
            FlashControlsOverlay(model: model)
        case .documentScanner:
            EmptyView()
        }
    }

    // MARK: - Captured Photo Preview

    @ViewBuilder
    private func capturePreview(image: UIImage) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Primary action
                    Button {
                        captures.append(image)
                        withAnimation { model.capturedImage = nil }
                    } label: {
                        Text("Continue")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    // Secondary actions
                    HStack(spacing: 16) {
                        Button {
                            withAnimation { model.capturedImage = nil }
                        } label: {
                            Label("Retake", systemImage: "arrow.counterclockwise")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("Captured Photo", image: Image(uiImage: image))
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        ZStack {
            Color(uiColor: .systemGray5).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("Camera Access Required")
                        .font(.title3.weight(.semibold))
                    Text("Allow camera access to see the live viewfinder demo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Allow Access") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
        }
    }
}

// MARK: - Standard Controls Overlay

struct StandardControlsOverlay: View {
    @ObservedObject var model: CameraModel

    var body: some View {
        VStack {
            // Top bar
            HStack(spacing: 20) {
                Image(systemName: "bolt.slash")
                Spacer()
                Image(systemName: "timer")
                Spacer()
                Image(systemName: "ellipsis")
            }
            .font(.system(size: 20))
            .foregroundStyle(.white)
            .shadow(radius: 3)
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 16)

            Spacer()

            // Bottom bar
            HStack {
                // Flip
                Button { model.flipCamera() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
                .frame(maxWidth: .infinity)

                // Shutter
                shutterButton

                // Thumbnail
                Group {
                    if let img = model.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private var shutterButton: some View {
        Button { model.capturePhoto() } label: {
            ZStack {
                Circle().stroke(.white, lineWidth: 4).frame(width: 70, height: 70)
                Circle().fill(.white).frame(width: 58, height: 58)
            }
            .shadow(radius: 6)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Minimal Scan Overlay

struct MinimalScanOverlay: View {
    @ObservedObject var model: CameraModel
    var showShutter: Bool = true

    var body: some View {
        ZStack {
            // Corner brackets
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let inset: CGFloat = 52

                ZStack {
                    bracketView().position(x: inset, y: inset)
                    bracketView().rotationEffect(.degrees(90)).position(x: w - inset, y: inset)
                    bracketView().rotationEffect(.degrees(-90)).position(x: inset, y: h - inset)
                    bracketView().rotationEffect(.degrees(180)).position(x: w - inset, y: h - inset)
                }
                .allowsHitTesting(false)

                // Crosshair
                ZStack {
                    Rectangle().fill(Color.white.opacity(0.5)).frame(width: 20, height: 2)
                    Rectangle().fill(Color.white.opacity(0.5)).frame(width: 2, height: 20)
                }
                .position(x: w / 2, y: h / 2)
                .allowsHitTesting(false)

                // Shutter at very bottom (not shown for scan-only modes)
                if showShutter {
                    Button { model.capturePhoto() } label: {
                        ZStack {
                            Circle().stroke(.white, lineWidth: 4).frame(width: 70, height: 70)
                            Circle().fill(.white).frame(width: 58, height: 58)
                        }
                        .shadow(radius: 6)
                    }
                    .position(x: w / 2, y: h - 80)
                }
            }
        }
    }

    private func bracketView() -> some View {
        let arm: CGFloat = 28
        return ZStack {
            Rectangle().fill(Color.white).frame(width: arm, height: 3)
            Rectangle().fill(Color.white).frame(width: 3, height: arm)
        }
    }
}

// MARK: - Floating Social Overlay

struct FloatingSocialOverlay: View {
    @ObservedObject var model: CameraModel

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .center, spacing: 20) {
                Spacer()

                // Pill shutter button
                Button { model.capturePhoto() } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.85))
                            .frame(width: 80, height: 80)
                        Circle()
                            .stroke(.white, lineWidth: 3)
                            .frame(width: 80, height: 80)
                    }
                    .shadow(radius: 8)
                }

                // Flip icon
                Button { model.flipCamera() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()
            }
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Video Controls Overlay

struct VideoControlsOverlay: View {
    @ObservedObject var model: CameraModel

    var body: some View {
        VStack {
            // Top bar with duration
            HStack {
                if model.isRecording {
                    HStack(spacing: 6) {
                        Circle().fill(Color.red).frame(width: 10, height: 10)
                        Text(durationString)
                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5), in: Capsule())
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 16)

            Spacer()

            // Bottom bar
            HStack {
                Button { model.flipCamera() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
                .frame(maxWidth: .infinity)

                // Record button
                Button {
                    if model.isRecording { model.stopRecording() }
                    else { model.startRecording() }
                } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 4).frame(width: 72, height: 72)
                        if model.isRecording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                        } else {
                            Circle().fill(Color.red).frame(width: 56, height: 56)
                        }
                    }
                    .shadow(radius: 6)
                }
                .frame(maxWidth: .infinity)

                // Thumbnail
                Group {
                    if let img = model.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private var durationString: String {
        let d = Int(model.recordingDuration)
        let m = d / 60
        let s = d % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Flash Controls Overlay

struct FlashControlsOverlay: View {
    @ObservedObject var model: CameraModel

    private let modes: [(label: String, mode: AVCaptureDevice.FlashMode, icon: String)] = [
        ("Off",   .off,  "bolt.slash"),
        ("Auto",  .auto, "bolt.badge.a"),
        ("On",    .on,   "bolt"),
    ]

    var body: some View {
        VStack {
            // Top bar with flash picker
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    ForEach(modes, id: \.label) { item in
                        Button {
                            model.flashMode = item.mode
                            if item.mode != .on { model.setTorch(on: false) }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 18))
                                Text(item.label)
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(model.flashMode == item.mode ? .yellow : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                model.flashMode == item.mode
                                    ? Color.white.opacity(0.15)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                    }

                    // Torch toggle
                    Button {
                        model.setTorch(on: true)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "flashlight.on.fill")
                                .font(.system(size: 18))
                            Text("Torch")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 52)
            .padding(.bottom, 12)

            Spacer()

            // Bottom bar
            HStack {
                Button { model.flipCamera() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
                .frame(maxWidth: .infinity)

                Button { model.capturePhoto() } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 4).frame(width: 70, height: 70)
                        Circle().fill(.white).frame(width: 58, height: 58)
                    }
                    .shadow(radius: 6)
                }
                .frame(maxWidth: .infinity)

                Group {
                    if let img = model.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Grid Overlay View

struct GridOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                // Vertical lines at 1/3 and 2/3
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))
                // Horizontal lines at 1/3 and 2/3
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - QR Bounds Overlay

struct QRBoundsOverlay: View {
    let codes: [CameraModel.DetectedCode]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ForEach(codes) { code in
                let b = code.bounds
                // Vision coords: origin bottom-left, y-flipped for UIKit
                let rect = CGRect(
                    x: b.minX * w,
                    y: (1 - b.maxY) * h,
                    width: b.width * w,
                    height: b.height * h
                )

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)

                    Text(code.stringValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 4))
                        .offset(y: -20)
                }
                .position(x: rect.midX, y: rect.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Face Boxes Overlay

struct FaceBoxesOverlay: View {
    let rects: [CGRect]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ForEach(Array(rects.enumerated()), id: \.offset) { _, r in
                let rect = CGRect(
                    x: r.minX * w,
                    y: (1 - r.maxY) * h,
                    width: r.width * w,
                    height: r.height * h
                )

                Rectangle()
                    .stroke(Color.teal, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - OCR Overlay

struct OCROverlay: View {
    let boxes: [CGRect]
    let texts: [String]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pairs = Array(zip(boxes, texts))

            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                let (r, text) = pair
                let rect = CGRect(
                    x: r.minX * w,
                    y: (1 - r.maxY) * h,
                    width: r.width * w,
                    height: r.height * h
                )

                ZStack {
                    Rectangle()
                        .stroke(Color.yellow.opacity(0.8), lineWidth: 1)
                        .frame(width: rect.width, height: rect.height)

                    Text(text)
                        .font(.system(size: max(10, rect.height * 0.5)))
                        .foregroundStyle(.yellow)
                        .lineLimit(1)
                        .frame(width: rect.width, alignment: .leading)
                        .offset(y: rect.height / 2 + 4)
                }
                .position(x: rect.midX, y: rect.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        LiveCameraView(config: .standardCentered, captures: .constant([]))
    }
}
