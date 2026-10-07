// OscillaCaptureController.swift — Oscilla Lab v0.1
//
// The 15-second capture loop from OSCILLA.md: while armed, ReplayKit keeps a
// rolling buffer of the last 15 seconds of play; "save" exports that buffer
// to a clip on demand (play → capture → share). ReplayKit's
// exportClip(to:duration:) is system-capped at min(elapsed, 15 seconds) —
// that cap IS the product spec, not a limitation we work around. Recording
// covers the whole app screen (ReplayKit has no per-view capture); only one
// recorder exists app-wide, and isAvailable is false on the simulator and
// while another recording runs, so the feature hides entirely behind
// .unavailable there. The first arm presents the system consent alert, so
// arm() is only ever called from an explicit user tap — never onAppear.

import SwiftUI
import ReplayKit

// RPScreenRecorderDelegate extends NSObjectProtocol → MUST subclass NSObject,
// with the conformance ON THE CLASS (not an extension) so the nonisolated
// witness can live with the type.
@MainActor
final class OscillaCaptureController: NSObject, ObservableObject, RPScreenRecorderDelegate {

    /// Capture state machine. unavailable hides the feature entirely;
    /// idle ⇄ buffering on arm/disarm; buffering → exporting → buffering
    /// around a save (the rolling buffer keeps running underneath an export).
    enum Phase { case unavailable, idle, buffering, exporting }

    @Published var phase: Phase
    /// A finished export — drives the share sheet via `.sheet(item:)`.
    @Published var exportedClip: CaptureClip?

    struct CaptureClip: Identifiable {
        let id = UUID()
        let url: URL
    }

    override init() {
        phase = RPScreenRecorder.shared().isAvailable ? .idle : .unavailable
        super.init()
        RPScreenRecorder.shared().delegate = self
        cleanClipsDirectory()
    }

    // MARK: - Capture controls

    /// Start the rolling 15s buffer. Only ever called from an explicit user
    /// tap — the first start presents the system consent alert. Errors
    /// (consent denied, recorder busy) drop quietly back to idle: no alert
    /// spam, the button is simply there to try again.
    func arm() {
        guard phase == .idle else { return }
        Task {
            do {
                try await RPScreenRecorder.shared().startClipBuffering()
                if phase == .idle { phase = .buffering }
            } catch {
                // Back in idle: phase was never set optimistically, so the
                // failing path never left .idle. If it reads .buffering here,
                // a concurrent arm genuinely succeeded (leave it); if
                // .unavailable, the delegate flipped it (leave that too).
            }
        }
    }

    /// Stop the rolling buffer. Called from the explicit stop tap, from
    /// onDisappear, and when scenePhase leaves .active — disarming twice is
    /// a cheap no-op. Also bails out of an in-flight export: the export
    /// completion sees phase != .exporting and leaves .idle alone.
    func disarm() {
        guard phase == .buffering || phase == .exporting else { return }
        phase = .idle
        Task {
            do {
                try await RPScreenRecorder.shared().stopClipBuffering()
            } catch {
                // Already idle; nothing to restore. ReplayKit owns whatever
                // teardown is left.
            }
        }
    }

    /// Export the last 15 seconds (ReplayKit caps duration at
    /// min(elapsed, 15)) into a temp file and hand it to the share sheet.
    /// Buffering continues underneath — saving never interrupts play.
    func saveClip() {
        guard phase == .buffering else { return }
        phase = .exporting
        Task {
            do {
                let url = try newClipURL()
                try await RPScreenRecorder.shared().exportClip(to: url, duration: 15)
                if phase == .exporting {
                    exportedClip = CaptureClip(url: url)
                    phase = .buffering
                } else {
                    // Disarmed (or went unavailable) mid-export — there is
                    // no share sheet to feed; drop the orphaned file.
                    deleteClip(url)
                }
            } catch {
                // Export (or clip-directory creation) failed: fall back to
                // buffering — the rolling buffer is still live.
                if phase == .exporting { phase = .buffering }
            }
        }
    }

    // MARK: - RPScreenRecorderDelegate

    /// The delegate requirement is nonisolated — witness it nonisolated and
    /// hop to the main actor. Availability going false while buffering or
    /// exporting collapses to .unavailable (ReplayKit already tore the
    /// session down); coming back true restores .idle only from .unavailable
    /// so a live phase is never clobbered.
    nonisolated func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        Task { @MainActor in
            self.phase = RPScreenRecorder.shared().isAvailable
                ? (self.phase == .unavailable ? .idle : self.phase)
                : .unavailable
        }
    }

    // MARK: - Clip files

    /// Best-effort cleanup after the share sheet dismisses (and for orphaned
    /// exports). Failure is harmless — the init sweep and the OS's tmp
    /// reclamation both catch stragglers.
    func deleteClip(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Clips live in their own subdirectory of tmp so the init sweep can
    /// clear stale ones without touching anything else in temporaryDirectory.
    private var clipsDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("OscillaClips", isDirectory: true)
    }

    /// A fresh destination for one export; creates the directory on demand.
    private func newClipURL() throws -> URL {
        try FileManager.default.createDirectory(
            at: clipsDirectory, withIntermediateDirectories: true)
        return clipsDirectory
            .appendingPathComponent("oscilla-\(UUID().uuidString).mp4")
    }

    /// Best-effort sweep of clips left behind by a previous session (e.g.
    /// the app died while the share sheet was up).
    private func cleanClipsDirectory() {
        try? FileManager.default.removeItem(at: clipsDirectory)
    }
}
