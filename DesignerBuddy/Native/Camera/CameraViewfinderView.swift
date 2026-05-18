import SwiftUI
import AVFoundation
import Combine
import Vision

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

final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
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

// MARK: - Delegate helpers (file-scope NSObject subclasses)

private final class MetadataCaptureDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let handler: ([AVMetadataObject]) -> Void
    init(handler: @escaping ([AVMetadataObject]) -> Void) { self.handler = handler }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        handler(metadataObjects)
    }
}

private final class VideoDataDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let handler: (CMSampleBuffer) -> Void
    init(handler: @escaping (CMSampleBuffer) -> Void) { self.handler = handler }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        handler(sampleBuffer)
    }
}

// MARK: - Movie File Output Delegate

private final class MovieOutputDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {}
}

// MARK: - Camera Model

@MainActor
final class CameraModel: NSObject, ObservableObject {
    // MARK: Published state
    @Published var isAuthorized = false
    @Published var isRunning = false
    @Published var isFrontCamera = false
    @Published var capturedImage: UIImage? = nil
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var detectedFaces: [CGRect] = []
    @Published var detectedCodes: [DetectedCode] = []
    @Published var recognizedTextBoxes: [CGRect] = []
    @Published var recognizedTextStrings: [String] = []

    struct DetectedCode: Identifiable {
        let id = UUID()
        let bounds: CGRect   // normalized 0–1
        let stringValue: String
    }

    // MARK: Session
    let config: CameraConfig
    let session = AVCaptureSession()

    private let photoOutput    = AVCapturePhotoOutput()
    private let movieOutput    = AVCaptureMovieFileOutput()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()

    private var captureProcessor: PhotoCaptureProcessor?
    private var movieDelegate: MovieOutputDelegate?
    private var isSettingUp = false
    private var recordingTimer: Timer?

    // Lazily created delegate objects
    private lazy var metadataDelegate = MetadataCaptureDelegate { [weak self] objects in
        Task { @MainActor [weak self] in self?.handleMetadata(objects) }
    }
    private lazy var videoDataDelegate = VideoDataDelegate { [weak self] buffer in
        self?.handleVideoFrame(buffer)
    }

    // Frame counter — only mutated on the background serial queue, safe to mark nonisolated(unsafe)
    nonisolated(unsafe) private var frameCounter = 0

    init(config: CameraConfig) {
        self.config = config
        super.init()
    }

    // MARK: - Authorization

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

    // MARK: - Session Setup

    func setupSession() {
        guard isAuthorized, !isSettingUp, !session.isRunning else { return }
        isSettingUp = true

        let cfg = config
        Task.detached { [weak self] in
            guard let self else { return }
            let session     = await self.session
            let photoOutput = await self.photoOutput
            let movieOutput = await self.movieOutput
            let metaOutput  = await self.metadataOutput
            let videoOutput = await self.videoDataOutput

            session.beginConfiguration()

            // Input
            let position = cfg.devicePosition
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                let input  = try? AVCaptureDeviceInput(device: device)
            else {
                session.commitConfiguration()
                await MainActor.run { self.isSettingUp = false }
                return
            }
            if session.canAddInput(input) { session.addInput(input) }

            // Output
            switch cfg {
            case .video:
                if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }

            case .qrBarcodeScanner:
                if session.canAddOutput(metaOutput) {
                    session.addOutput(metaOutput)
                    // metadata types must be set after adding to session
                    let types: [AVMetadataObject.ObjectType] = [
                        .qr, .ean8, .ean13, .code128, .pdf417
                    ]
                    let supported = metaOutput.availableMetadataObjectTypes
                    metaOutput.metadataObjectTypes = types.filter { supported.contains($0) }
                    let delegate = await self.metadataDelegate
                    metaOutput.setMetadataObjectsDelegate(delegate, queue: .main)
                }

            case .faceDetection, .liveOCR:
                videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                let delegate = await self.videoDataDelegate
                let q = DispatchQueue(label: "com.designerbuddy.videodata", qos: .userInitiated)
                videoOutput.setSampleBufferDelegate(delegate, queue: q)
                if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

            default:
                if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            }

            session.commitConfiguration()
            session.startRunning()

            await MainActor.run {
                self.isRunning    = true
                self.isSettingUp  = false
            }
        }
    }

    // MARK: - Tear Down

    func tearDownSession() {
        isSettingUp = false
        stopRecordingTimer()
        Task.detached { [weak self] in
            guard let self else { return }
            let session = await self.session
            if session.isRunning { session.stopRunning() }
            session.beginConfiguration()
            for input in session.inputs   { session.removeInput(input) }
            for output in session.outputs { session.removeOutput(output) }
            session.commitConfiguration()
            await MainActor.run { self.isRunning = false }
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() {
        guard photoOutput.connection(with: .video)?.isActive == true else { return }
        let processor = PhotoCaptureProcessor()
        captureProcessor = processor
        processor.onCapture = { [weak self] image in
            Task { @MainActor [weak self] in
                self?.capturedImage = image
                self?.captureProcessor = nil
            }
        }
        var settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }

    // MARK: - Video Recording

    func startRecording() {
        guard !isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        let del = MovieOutputDelegate()
        movieDelegate = del
        movieOutput.startRecording(to: url, recordingDelegate: del)
        isRecording = true
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recordingDuration += 1
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        isRecording = false
        stopRecordingTimer()
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Flip Camera

    func flipCamera() {
        Task.detached { [weak self] in
            guard let self else { return }
            let session = await self.session
            session.beginConfiguration()
            for input in session.inputs { session.removeInput(input) }
            let currentlyFront = await self.isFrontCamera
            let newPosition: AVCaptureDevice.Position = currentlyFront ? .back : .front
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                session.commitConfiguration()
                return
            }
            if session.canAddInput(input) { session.addInput(input) }
            session.commitConfiguration()
            await MainActor.run { self.isFrontCamera = !currentlyFront }
        }
    }

    // MARK: - Torch

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    // MARK: - Metadata Handler (QR / Barcode)

    func handleMetadata(_ objects: [AVMetadataObject]) {
        var codes: [DetectedCode] = []
        for obj in objects {
            guard let machineReadable = obj as? AVMetadataMachineReadableCodeObject,
                  let string = machineReadable.stringValue else { continue }
            let bounds = machineReadable.bounds
            codes.append(DetectedCode(bounds: bounds, stringValue: string))
        }
        detectedCodes = codes
    }

    // MARK: - Video Frame Handler (Face Detection / OCR)

    nonisolated func handleVideoFrame(_ buffer: CMSampleBuffer) {
        frameCounter += 1
        guard frameCounter % 3 == 0 else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .right,
                                            options: [:])

        // Capture config without actor hop (it's a let)
        let cfg = config

        if cfg == .faceDetection {
            let request = VNDetectFaceRectanglesRequest { [weak self] req, _ in
                guard let self else { return }
                let rects = (req.results as? [VNFaceObservation])?.map { $0.boundingBox } ?? []
                Task { @MainActor in self.detectedFaces = rects }
            }
            try? handler.perform([request])

        } else if cfg == .liveOCR {
            let request = VNRecognizeTextRequest { [weak self] req, _ in
                guard let self else { return }
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let boxes   = observations.map { $0.boundingBox }
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                Task { @MainActor in
                    self.recognizedTextBoxes   = boxes
                    self.recognizedTextStrings = strings
                }
            }
            request.recognitionLevel = .fast
            try? handler.perform([request])
        }
    }
}
