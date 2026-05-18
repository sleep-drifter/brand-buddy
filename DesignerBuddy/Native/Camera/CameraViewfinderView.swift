import SwiftUI
import AVFoundation
import Combine

// MARK: - Camera Preview UIView Wrapper

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Photo Capture Processor

private final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage?) -> Void)?

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else {
            onCapture?(nil)
            return
        }
        onCapture?(UIImage(data: data))
    }
}

// MARK: - Camera Model

@MainActor
final class CameraModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var isRunning = false
    @Published var isFrontCamera = false
    @Published var capturedImage: UIImage? = nil

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureProcessor: PhotoCaptureProcessor?

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                isAuthorized = granted
            }
        default:
            isAuthorized = false
        }
    }

    func setupSession() {
        guard isAuthorized else { return }
        Task.detached { [weak self] in
            guard let self else { return }
            let session = await self.session
            let photoOutput = await self.photoOutput
            session.beginConfiguration()
            let position: AVCaptureDevice.Position = await self.isFrontCamera ? .front : .back
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                session.commitConfiguration()
                return
            }
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            session.commitConfiguration()
            session.startRunning()
            await MainActor.run { self.isRunning = true }
        }
    }

    func flipCamera() {
        Task.detached { [weak self] in
            guard let self else { return }
            let session = await self.session
            session.beginConfiguration()
            for input in session.inputs { session.removeInput(input) }
            let newFront = await !self.isFrontCamera
            await MainActor.run { self.isFrontCamera = newFront }
            let position: AVCaptureDevice.Position = newFront ? .front : .back
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                session.commitConfiguration()
                return
            }
            if session.canAddInput(input) { session.addInput(input) }
            session.commitConfiguration()
        }
    }

    func capturePhoto() {
        let processor = PhotoCaptureProcessor()
        captureProcessor = processor
        processor.onCapture = { [weak self] image in
            Task { @MainActor [weak self] in
                self?.capturedImage = image
                self?.captureProcessor = nil
            }
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }
}

// MARK: - Main View

struct CameraViewfinderView: View {
    @StateObject private var model = CameraModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.isAuthorized {
                viewfinderLayer
            } else {
                permissionCard
            }

            if let image = model.capturedImage {
                capturePreview(image: image)
                    .transition(.opacity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            model.checkAuthorization()
            if model.isAuthorized { model.setupSession() }
        }
        .onChange(of: model.isAuthorized) { _, authorized in
            if authorized { model.setupSession() }
        }
        .onDisappear {
            model.session.stopRunning()
        }
        .animation(.easeInOut(duration: 0.25), value: model.capturedImage != nil)
    }

    // MARK: - Viewfinder Layer

    private var viewfinderLayer: some View {
        ZStack {
            CameraPreviewView(session: model.session)
                .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Text("Camera Viewfinder")
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(radius: 4)
            Text("LIVE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.red))
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button { model.flipCamera() } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .frame(maxWidth: .infinity)

            shutterButton

            Button {} label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }

    private var shutterButton: some View {
        Button { model.capturePhoto() } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                Circle()
                    .fill(.white)
                    .frame(width: 58, height: 58)
            }
            .shadow(radius: 6)
        }
        .frame(maxWidth: .infinity)
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
                HStack(spacing: 24) {
                    Button {
                        withAnimation { model.capturedImage = nil }
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    ShareLink(item: Image(uiImage: image), preview: SharePreview("Captured Photo", image: Image(uiImage: image))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.blue, in: Capsule())
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        ZStack {
            Color(uiColor: .systemGray5)
                .ignoresSafeArea()

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

#Preview {
    NavigationStack {
        CameraViewfinderView()
    }
}
