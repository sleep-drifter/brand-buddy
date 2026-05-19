import AVFoundation

// MARK: - Camera Config Category

enum CameraConfigCategory: String, CaseIterable {
    case positionsAndLenses = "Camera Positions & Lenses"
    case uiLayoutPatterns   = "UI Layout Patterns"
    case captureModes       = "Capture Modes"
    case hudOverlay         = "HUD / Overlay"
    case cameraControls     = "Camera Controls"
    case scanAndDetection   = "Scan & Detection"
}

// MARK: - Camera Config

enum CameraConfig: String, CaseIterable, Identifiable {
    // Camera Positions & Lenses
    case backWide       = "back-wide"
    case frontSelfie    = "front-selfie"

    // UI Layout Patterns
    case standardCentered    = "standard-centered"
    case minimalScan         = "minimal-scan"
    case floatingSocial      = "floating-social"

    // Capture Modes
    case photo       = "photo"
    case video       = "video"
    case freeCrop    = "free-crop"
    case circularCrop = "circular-crop"

    // HUD / Overlay
    case gridOverlay = "grid-overlay"

    // Camera Controls
    case flashControl = "flash-control"

    // Scan & Detection
    case documentScanner  = "document-scanner"
    case qrBarcodeScanner = "qr-barcode-scanner"
    case faceDetection    = "face-detection"
    case liveOCR          = "live-ocr"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backWide:            return "Back — Wide (1×)"
        case .frontSelfie:         return "Front (Selfie)"
        case .standardCentered:    return "Standard Centered"
        case .minimalScan:         return "Minimal / Scan"
        case .floatingSocial:      return "Floating / Social"
        case .photo:               return "Photo"
        case .video:               return "Video"
        case .freeCrop:            return "Free-Form Crop"
        case .circularCrop:        return "Circular Crop"
        case .gridOverlay:         return "Grid Overlay"
        case .flashControl:        return "Flash Control"
        case .documentScanner:     return "Document Scanner"
        case .qrBarcodeScanner:    return "QR / Barcode Scanner"
        case .faceDetection:       return "Face Detection"
        case .liveOCR:             return "Live OCR"
        }
    }

    var subtitle: String {
        switch self {
        case .backWide:            return "Back camera, wide angle, standard centered UI"
        case .frontSelfie:         return "Front-facing camera, standard centered UI"
        case .standardCentered:    return "Shutter center, flip + thumbnail on sides"
        case .minimalScan:         return "Full-bleed viewfinder, corner brackets, shutter bottom-center"
        case .floatingSocial:      return "Semi-transparent pill shutter, no chrome, no top bar"
        case .photo:               return "Standard UI highlighting photo output"
        case .video:               return "Red record button, live recording duration"
        case .freeCrop:            return "Capture then drag 8 handles to crop any region"
        case .circularCrop:        return "Capture then pan/zoom image behind fixed circle mask"
        case .gridOverlay:         return "Two-thirds rule grid lines over the viewfinder"
        case .flashControl:        return "Flash mode picker: Off / Auto / On / Torch"
        case .documentScanner:     return "System document scanner (VNDocumentCameraViewController)"
        case .qrBarcodeScanner:    return "AVCaptureMetadataOutput with bounding-box overlay"
        case .faceDetection:       return "Vision face rectangles overlaid per frame"
        case .liveOCR:             return "Vision text recognition overlaid per frame (fast mode)"
        }
    }

    var icon: String {
        switch self {
        case .backWide:            return "camera"
        case .frontSelfie:         return "camera.on.rectangle"
        case .standardCentered:    return "camera.viewfinder"
        case .minimalScan:         return "viewfinder"
        case .floatingSocial:      return "bubbles.and.sparkles"
        case .photo:               return "photo"
        case .video:               return "video"
        case .freeCrop:            return "crop"
        case .circularCrop:        return "circle.dashed"
        case .gridOverlay:         return "grid"
        case .flashControl:        return "bolt"
        case .documentScanner:     return "doc.text.viewfinder"
        case .qrBarcodeScanner:    return "qrcode.viewfinder"
        case .faceDetection:       return "face.smiling"
        case .liveOCR:             return "character.magnify"
        }
    }

    var category: CameraConfigCategory {
        switch self {
        case .backWide, .frontSelfie:
            return .positionsAndLenses
        case .standardCentered, .minimalScan, .floatingSocial:
            return .uiLayoutPatterns
        case .photo, .video, .freeCrop, .circularCrop:
            return .captureModes
        case .gridOverlay:
            return .hudOverlay
        case .flashControl:
            return .cameraControls
        case .documentScanner, .qrBarcodeScanner, .faceDetection, .liveOCR:
            return .scanAndDetection
        }
    }

    /// The AVFoundation device position this config uses
    var devicePosition: AVCaptureDevice.Position {
        switch self {
        case .frontSelfie: return .front
        default:           return .back
        }
    }
}
