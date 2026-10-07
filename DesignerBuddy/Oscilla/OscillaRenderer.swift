// OscillaRenderer.swift — Oscilla Lab v0
//
// The synth's voice: shader composition. Takes a patch's layer stack plus the
// resolved [layer][param] values from OscillaEval.layerParams and folds the
// engines over Color.black, one SwiftUI shader effect per layer. Each engine
// case maps its normalized 0–1 params to the physical shader arguments,
// mirroring the shipped call sites in ShadersPlaygroundView.applyEffect and
// FluidGradientView argument-for-argument. Pure function of
// (patch, params, time, size, tapPoint) — no state, no views of its own.

import SwiftUI
import UIKit

/// Composites a patch's layer stack. Pure function of (patch, params, time,
/// size, tapPoint). Mirrors ShadersPlaygroundView.applyEffect exactly.
struct OscillaRenderer {

    /// Folds layers over Color.black. `params` comes from OscillaEval.layerParams.
    /// `size` is the laid-out point size (used for .float2(size) args). `tap`
    /// feeds circleWave/starNest center (defaults to center of size).
    static func render(patch: OscillaPatch, params: [[Float]],
                       time: Float, size: CGSize, tap: CGPoint?) -> AnyView {
        let center = tap ?? CGPoint(x: size.width / 2, y: size.height / 2)
        return zip(patch.layers, params).reduce(AnyView(Color.black)) { acc, pair in
            applyEngine(pair.0.engine, to: acc, p: pair.1, time: time,
                        size: size, center: center, tint: patch.tint.color)
        }
    }

    // MARK: - Engine dispatch

    /// One shader application. Switch-based with exactly one return per case
    /// (type-checker safety — never build engine calls inline in the reduce
    /// closure). A params slice shorter than the engine expects is a data bug;
    /// the layer is passed through untouched rather than crashing.
    private static func applyEngine(_ engine: OscillaEngine, to view: AnyView,
                                    p: [Float], time: Float, size: CGSize,
                                    center: CGPoint, tint: Color) -> AnyView {
        guard p.count >= engine.paramCount else { return view }

        switch engine {
        case .chromaField:
            let hsb: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) = tintHSB(tint)
            let bg: (Float, Float, Float) = (0.03, 0.03, 0.05)   // fixed dark canvas
            let c0: (Float, Float, Float, Float) = blobColor(hsb: hsb, hueOffset: -0.10)
            let c1: (Float, Float, Float, Float) = blobColor(hsb: hsb, hueOffset: -0.05)
            let c2: (Float, Float, Float, Float) = blobColor(hsb: hsb, hueOffset: 0)
            let c3: (Float, Float, Float, Float) = blobColor(hsb: hsb, hueOffset: 0.05)
            let c4: (Float, Float, Float, Float) = blobColor(hsb: hsb, hueOffset: 0.10)
            return AnyView(view.colorEffect(
                ShaderLibrary.chromaGradientArt(
                    .float2(size),
                    .float(time * (p[0] * 2)),        // p0 speed
                    .float(p[1] * 0.2),               // p1 grain
                    .float(0.5 + p[2]),               // p2 zoom
                    .float3(bg.0, bg.1, bg.2),
                    .float(p[3] * 2),                 // p3 saturation
                    .float(0.5 + p[4] * 1.5),         // p4 softness
                    .float(p[5] * 2),                 // p5 warp
                    .float(5),                        // blobCount fixed 5
                    .float4(c0.0, c0.1, c0.2, c0.3),
                    .float4(c1.0, c1.1, c1.2, c1.3),
                    .float4(c2.0, c2.1, c2.2, c2.3),
                    .float4(c3.0, c3.1, c3.2, c3.3),
                    .float4(c4.0, c4.1, c4.2, c4.3),
                    .float(0),                        // aberration
                    .float(0.35),                     // vignette
                    .float(0)                         // hueShift
                )
            ))

        case .starNest:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderStarNest(
                    .float2(size),
                    .float(time),
                    .float(0.001 + p[0] * 0.049),     // speed
                    .float(0.4 + p[1] * 1.2),         // zoom
                    .float(0.45 + p[2] * 0.2),        // formuparam
                    .float(0.0005 + p[3] * 0.0045),   // brightness
                    .float(p[4]),                     // saturation
                    .float2(center)
                )
            ))

        case .domainWarp:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderDomainWarp(
                    .float2(size),
                    .float(time),
                    .float(p[0] * 120),
                    .float(1 + p[1] * 7),
                    .float(p[2] < 0.5 ? 1 : 2),
                    .float(p[3] * 1.5)
                ),
                maxSampleOffset: CGSize(width: 120, height: 120)
            ))

        case .water:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderWater(
                    .float2(size),
                    .float(time),
                    .float(0.5 + p[0] * 9.5),
                    .float(1 + p[1] * 4),
                    .float(5 + p[2] * 20)
                ),
                maxSampleOffset: CGSize(width: 12, height: 12)
            ))

        case .circleWave:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderCircleWave(
                    .float2(size),
                    .float(time),
                    .float(p[0] * 2),                 // brightness
                    .float(-2 + p[1] * 4),            // speed (± = direction)
                    .float(0.02 + p[2] * 2.98),       // strength
                    .float(20 + p[3] * 480),          // density
                    .float2(center),
                    .float(p[4])                      // hue
                )
            ))

        case .metaballs:
            return AnyView(view.colorEffect(
                ShaderLibrary.randomMetaball2D(
                    .float2(size),
                    .float(time),
                    .float(1 + p[0] * 15),        // p0 count  → 1–16 balls (FIX in base data; int-cast pops if modulated)
                    .float(0.06 + p[1] * 0.28),   // p1 size
                    .float(0.1 + p[2] * 1.4),     // p2 speed  (scrubs phase: t = time*speed UNWRAPPED — knob-paced moves only; NEVER gate or LFO this param, the jump scales with session age)
                    .float(0.05 + p[3] * 0.5),    // p3 fusion (smooth-min smoothing)
                    .float(p[4])                  // p4 hue    (fence near patch tint hue in data)
                )
            ))

        case .grain:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderGrain(
                    .float(time),
                    .float(p[0] * 2.0),
                    .float(0.5 + p[1] * 19.5),
                    .float(0.4)
                )
            ))

        case .vignette:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderVignette(
                    .float2(size),
                    .float(p[0] * 2.5),               // radius
                    .float(p[1] * 1.5)                // softness
                )
            ))
        }
    }

    // MARK: - Blob color derivation (chromaField)

    /// Hue/saturation/brightness of the patch tint, read through UIColor.
    /// Falls back to a muted blue if the color cannot be decomposed.
    private static func tintHSB(_ tint: Color) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        let decomposed = UIColor(tint).getHue(&hue, saturation: &saturation,
                                              brightness: &brightness, alpha: &alpha)
        if !decomposed {
            hue = 0.6
            saturation = 0.5
            brightness = 0.8
        }
        return (hue: hue, saturation: saturation, brightness: brightness)
    }

    /// One blob RGBA at a hue offset from the tint's hue (wrapped into 0–1),
    /// keeping the tint's saturation and brightness. Alpha fixed at 0.9.
    private static func blobColor(hsb: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat),
                                  hueOffset: CGFloat) -> (Float, Float, Float, Float) {
        var shiftedHue = hsb.hue + hueOffset
        shiftedHue -= floor(shiftedHue)   // wrap into 0..<1
        let shifted = UIColor(hue: shiftedHue, saturation: hsb.saturation,
                              brightness: hsb.brightness, alpha: 1)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        shifted.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Float(red), Float(green), Float(blue), 0.9)
    }
}
