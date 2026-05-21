import Foundation
import CoreHaptics

// MARK: - Event

struct HapticStudioEvent: Identifiable, Equatable {
    var id = UUID()
    var time: Double            // seconds from pattern start
    var type: EventType
    var duration: Double        // only meaningful for .continuous
    var intensity: Float        // 0–1
    var sharpness: Float        // 0–1
    var attackTime: Float       // 0–1 (continuous only)
    var decayTime: Float        // 0–1 (continuous only)
    var releaseTime: Float      // 0–1 (continuous only)
    var sustained: Bool         // continuous only

    enum EventType: String, CaseIterable {
        case transient  = "HapticTransient"
        case continuous = "HapticContinuous"
    }

    static func defaultTransient(at time: Double) -> HapticStudioEvent {
        HapticStudioEvent(time: time, type: .transient, duration: 0,
                          intensity: 0.8, sharpness: 0.5,
                          attackTime: 0, decayTime: 0, releaseTime: 0, sustained: false)
    }

    static func defaultContinuous(at time: Double, duration: Double = 0.3) -> HapticStudioEvent {
        HapticStudioEvent(time: time, type: .continuous, duration: duration,
                          intensity: 0.6, sharpness: 0.3,
                          attackTime: 0, decayTime: 0, releaseTime: 0, sustained: true)
    }

    func toCHHapticEvent() -> CHHapticEvent {
        var params: [CHHapticEventParameter] = [
            .init(parameterID: .hapticIntensity, value: intensity),
            .init(parameterID: .hapticSharpness, value: sharpness),
        ]
        if type == .continuous {
            if attackTime  > 0 { params.append(.init(parameterID: .attackTime,   value: attackTime)) }
            if decayTime   > 0 { params.append(.init(parameterID: .decayTime,    value: decayTime)) }
            if releaseTime > 0 { params.append(.init(parameterID: .releaseTime,  value: releaseTime)) }
            params.append(.init(parameterID: .sustained, value: sustained ? 1 : 0))
            return CHHapticEvent(eventType: .hapticContinuous, parameters: params,
                                 relativeTime: time, duration: max(duration, 0.01))
        } else {
            return CHHapticEvent(eventType: .hapticTransient, parameters: params, relativeTime: time)
        }
    }
}

// MARK: - Parameter Curve

struct HapticParameterCurve: Identifiable, Equatable {
    var id = UUID()
    var parameterID: CurveParam
    var controlPoints: [ControlPoint]

    enum CurveParam: String, CaseIterable, Identifiable {
        case intensity  = "HapticIntensityControl"
        case sharpness  = "HapticSharpnessControl"

        var id: String { rawValue }
        var label: String {
            switch self {
            case .intensity: return "Intensity"
            case .sharpness: return "Sharpness"
            }
        }
        var color: String {
            switch self {
            case .intensity: return "blue"
            case .sharpness: return "orange"
            }
        }
        var chID: CHHapticDynamicParameter.ID {
            switch self {
            case .intensity: return .hapticIntensityControl
            case .sharpness: return .hapticSharpnessControl
            }
        }
    }

    struct ControlPoint: Identifiable, Equatable {
        var id = UUID()
        var time: Double    // seconds
        var value: Float    // 0–1
    }

    func toCHParameterCurve() -> CHHapticParameterCurve {
        let pts = controlPoints.map {
            CHHapticParameterCurve.ControlPoint(relativeTime: $0.time, value: $0.value)
        }
        return CHHapticParameterCurve(parameterID: parameterID.chID, controlPoints: pts, relativeTime: 0)
    }
}

// MARK: - Pattern

struct HapticPattern {
    var events: [HapticStudioEvent] = []
    var curves: [HapticParameterCurve] = [
        HapticParameterCurve(parameterID: .intensity, controlPoints: []),
        HapticParameterCurve(parameterID: .sharpness, controlPoints: []),
    ]

    var totalDuration: Double {
        let eventEnd = events.map { $0.time + ($0.type == .continuous ? $0.duration : 0.1) }.max() ?? 1.0
        let curveEnd = curves.flatMap(\.controlPoints).map(\.time).max() ?? 0
        return max(eventEnd, curveEnd, 1.0)
    }
}

// MARK: - AHAP Export

struct AHAPPattern: Codable {
    var Version: Double = 1.0
    var Pattern: [AHAPElement]

    struct AHAPElement: Codable {
        var Event: AHAPEvent?
        var ParameterCurve: AHAPParameterCurve?

        private enum CodingKeys: String, CodingKey { case Event, ParameterCurve }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            if let e = Event { try c.encode(e, forKey: .Event) }
            if let p = ParameterCurve { try c.encode(p, forKey: .ParameterCurve) }
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            Event = try c.decodeIfPresent(AHAPEvent.self, forKey: .Event)
            ParameterCurve = try c.decodeIfPresent(AHAPParameterCurve.self, forKey: .ParameterCurve)
        }
        init(event: AHAPEvent) { Event = event; ParameterCurve = nil }
        init(curve: AHAPParameterCurve) { Event = nil; ParameterCurve = curve }
    }

    struct AHAPEvent: Codable {
        var Time: Double
        var EventType: String
        var EventDuration: Double?
        var EventParameters: [AHAPEventParam]
    }

    struct AHAPEventParam: Codable {
        var ParameterID: String
        var ParameterValue: Double
    }

    struct AHAPParameterCurve: Codable {
        var ParameterID: String
        var Time: Double = 0
        var ParameterCurveControlPoints: [AHAPControlPoint]
    }

    struct AHAPControlPoint: Codable {
        var Time: Double
        var ParameterValue: Double
    }
}

extension HapticPattern {
    func toAHAP() -> AHAPPattern {
        var elements: [AHAPPattern.AHAPElement] = []

        for event in events.sorted(by: { $0.time < $1.time }) {
            var params: [AHAPPattern.AHAPEventParam] = [
                .init(ParameterID: "HapticIntensity", ParameterValue: Double(event.intensity)),
                .init(ParameterID: "HapticSharpness", ParameterValue: Double(event.sharpness)),
            ]
            if event.type == .continuous {
                if event.attackTime  > 0 { params.append(.init(ParameterID: "AttackTime",   ParameterValue: Double(event.attackTime))) }
                if event.decayTime   > 0 { params.append(.init(ParameterID: "DecayTime",    ParameterValue: Double(event.decayTime))) }
                if event.releaseTime > 0 { params.append(.init(ParameterID: "ReleaseTime",  ParameterValue: Double(event.releaseTime))) }
            }
            let ahapEvent = AHAPPattern.AHAPEvent(
                Time: event.time,
                EventType: event.type.rawValue,
                EventDuration: event.type == .continuous ? event.duration : nil,
                EventParameters: params
            )
            elements.append(.init(event: ahapEvent))
        }

        for curve in curves where !curve.controlPoints.isEmpty {
            let pts = curve.controlPoints.sorted { $0.time < $1.time }.map {
                AHAPPattern.AHAPControlPoint(Time: $0.time, ParameterValue: Double($0.value))
            }
            elements.append(.init(curve: AHAPPattern.AHAPParameterCurve(
                ParameterID: curve.parameterID.rawValue, Time: 0,
                ParameterCurveControlPoints: pts
            )))
        }

        return AHAPPattern(Pattern: elements)
    }

    func toAHAPString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(toAHAP()),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
