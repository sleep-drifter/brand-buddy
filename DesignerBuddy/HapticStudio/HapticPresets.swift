import SwiftUI

// MARK: - Sharpness → Color (shared across all views)

func sharpnessColor(_ sharpness: Float) -> Color {
    // 0 = soft/warm (orange-amber), 1 = crisp/cool (indigo-blue)
    let hue = 0.06 + 0.62 * Double(sharpness)
    return Color(hue: hue, saturation: 0.78, brightness: 0.95)
}

// MARK: - Presets

enum HapticPreset: String, CaseIterable {
    case selection, soft, light, medium, heavy, rigid, warning, success, heartbeat, rumble

    var label: String { rawValue.capitalized }

    var events: [HapticStudioEvent] {
        switch self {
        case .selection:
            return [.init(time: 0, type: .transient, duration: 0,
                          intensity: 0.4, sharpness: 0.8, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)]
        case .soft:
            return [.init(time: 0, type: .transient, duration: 0,
                          intensity: 0.55, sharpness: 0.1, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)]
        case .light:
            return [.init(time: 0, type: .transient, duration: 0,
                          intensity: 0.45, sharpness: 0.45, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)]
        case .medium:
            return [.init(time: 0, type: .transient, duration: 0,
                          intensity: 0.7, sharpness: 0.5, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)]
        case .heavy:
            return [.init(time: 0, type: .transient, duration: 0,
                          intensity: 0.95, sharpness: 0.25, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)]
        case .rigid:
            return [.init(time: 0, type: .transient, duration: 0,
                          intensity: 0.9, sharpness: 1.0, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)]
        case .warning:
            return [
                .init(time: 0,    type: .transient, duration: 0, intensity: 0.9, sharpness: 0.9, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false),
                .init(time: 0.15, type: .transient, duration: 0, intensity: 0.7, sharpness: 0.9, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false),
            ]
        case .success:
            return [
                .init(time: 0,    type: .continuous, duration: 0.1, intensity: 0.3, sharpness: 0.1, attackTime: 0, decayTime: 0, releaseTime: 0.1, sustained: false),
                .init(time: 0.12, type: .transient,  duration: 0,   intensity: 0.55, sharpness: 0.35, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false),
            ]
        case .heartbeat:
            return [
                .init(time: 0,    type: .transient, duration: 0, intensity: 0.8, sharpness: 0.6, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false),
                .init(time: 0.12, type: .transient, duration: 0, intensity: 0.5, sharpness: 0.4, attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false),
            ]
        case .rumble:
            return [
                .init(time: 0, type: .continuous, duration: 0.6, intensity: 0.6, sharpness: 0.05, attackTime: 0.1, decayTime: 0, releaseTime: 0.2, sustained: true),
            ]
        }
    }
}
