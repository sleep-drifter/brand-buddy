// OscillaBenchView.swift — Oscilla Lab v0.1
//
// Bench-lite: a hidden DEV tuning editor, not the player-facing Bench from
// OSCILLA.md (that surface stays deferred). It edits a live patch's NUMBERS
// in place — knob curves and fences, LFO shape/period/depth, gate envelope
// times and haptic strength, layer base params, renderScale — so a designer
// can hear a change on the very next frame (the lab's heroSurface re-reads
// the bound patch every frame), then copy or share the tuned patch as JSON.
// Values only, NO structural edits (no adding/removing layers, knobs, LFOs,
// gates, targets, or poses; no engine swaps; no retargeting; no defaultValue
// edits): OscillaPerformance sizes its arrays once per patch, and value-only
// edits never desync them.

import SwiftUI
import UIKit

// @MainActor so helper methods (copyJSON → glassMorphHaptic, a @MainActor
// global) share body's isolation instead of erroring as nonisolated callers.
@MainActor
struct OscillaBenchView: View {
    @Binding var patch: OscillaPatch
    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(patch.knobs.indices, id: \.self) { knobSection($0) }
                ForEach(patch.lfos.indices, id: \.self) { lfoSection($0) }
                ForEach(patch.gates.indices, id: \.self) { gateSection($0) }
                ForEach(patch.layers.indices, id: \.self) { layerSection($0) }
                renderSection()
                exportSection()
            }
            .navigationTitle("Bench — \(patch.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    copyButton
                }
            }
        }
    }

    // MARK: - Sections (one small private func per section type)

    private func knobSection(_ i: Int) -> some View {
        Section("Knob \(i) — \(patch.knobs[i].label)") {
            Picker("Curve", selection: $patch.knobs[i].curve) {
                ForEach(KnobCurve.allCases, id: \.self) { curve in
                    Text(curve.rawValue)
                }
            }
            .pickerStyle(.segmented)
            ForEach(patch.knobs[i].targets.indices, id: \.self) { j in
                fenceRows(knob: i, target: j)
            }
        }
    }

    /// The from/to fence pair for one knob target, labeled by destination.
    @ViewBuilder
    private func fenceRows(knob i: Int, target j: Int) -> some View {
        let label = targetLabel(patch.knobs[i].targets[j])
        floatRow("\(label) from", value: $patch.knobs[i].targets[j].from, range: 0...1)
        floatRow("\(label) to", value: $patch.knobs[i].targets[j].to, range: 0...1)
    }

    private func lfoSection(_ i: Int) -> some View {
        Section("LFO \(i)") {
            Picker("Shape", selection: $patch.lfos[i].shape) {
                ForEach(LFOShape.allCases, id: \.self) { shape in
                    Text(shape.rawValue)
                }
            }
            .pickerStyle(.segmented)
            doubleRow("period (s)", value: $patch.lfos[i].period, range: 1...60)
            floatRow("depth", value: $patch.lfos[i].depth, range: 0...1)
        }
    }

    private func gateSection(_ i: Int) -> some View {
        Section("Gate \(i) — \(patch.gates[i].label)") {
            doubleRow("attack (s)", value: $patch.gates[i].attack, range: 0.01...0.5)
            doubleRow("release (s)", value: $patch.gates[i].release, range: 0.1...5)
            floatRow("haptic", value: $patch.gates[i].hapticIntensity, range: 0...1)
        }
    }

    private func layerSection(_ i: Int) -> some View {
        Section("Layer \(i) — \(patch.layers[i].engine.rawValue)") {
            ForEach(patch.layers[i].base.indices, id: \.self) { p in
                floatRow("p\(p)", value: $patch.layers[i].base[p], range: 0...1)
            }
        }
    }

    private func renderSection() -> some View {
        Section {
            LabeledContent("renderScale  \(patch.renderScale, specifier: "%.2f")") {
                Slider(value: $patch.renderScale, in: 0.25...1)
                    .frame(width: 150)
            }
        } header: {
            Text("Render")
        } footer: {
            Text("stored but unused in v0")
        }
    }

    private func exportSection() -> some View {
        Section("Export") {
            Button {
                copyJSON()
            } label: {
                Label("Copy JSON", systemImage: copied ? "checkmark.circle" : "doc.on.clipboard")
            }
            ShareLink(item: jsonString, preview: SharePreview("\(patch.id).json"))
        }
    }

    // MARK: - Rows

    /// LabeledContent + Slider row for a Float value, with a live readout.
    private func floatRow(_ label: String, value: Binding<Float>,
                          range: ClosedRange<Float>) -> some View {
        LabeledContent("\(label)  \(value.wrappedValue, specifier: "%.2f")") {
            Slider(value: value, in: range)
                .frame(width: 150)
        }
    }

    /// LabeledContent + Slider row for a Double value, with a live readout.
    private func doubleRow(_ label: String, value: Binding<Double>,
                           range: ClosedRange<Double>) -> some View {
        LabeledContent("\(label)  \(value.wrappedValue, specifier: "%.2f")") {
            Slider(value: value, in: range)
                .frame(width: 150)
        }
    }

    private func targetLabel(_ target: ParamTarget) -> String {
        "L\(target.layer).p\(target.param)"
    }

    // MARK: - Export

    private var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(patch),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private var copyButton: some View {
        Button {
            copyJSON()
        } label: {
            Image(systemName: copied ? "checkmark.circle" : "doc.on.clipboard")
        }
        .accessibilityLabel("Copy patch JSON")
    }

    private func copyJSON() {
        UIPasteboard.general.string = jsonString
        glassMorphHaptic(.soft)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            copied = false
        }
    }
}

// MARK: - Previews

private struct OscillaBenchPreviewHost: View {
    @State private var patch = OscillaFactory.drift

    var body: some View {
        OscillaBenchView(patch: $patch)
    }
}

#Preview {
    OscillaBenchPreviewHost()
}
