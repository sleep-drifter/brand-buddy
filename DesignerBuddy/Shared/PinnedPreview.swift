import SwiftUI

// Pins a live preview canvas above a scrolling container so controls can be
// adjusted with the preview always in view. Apply to the List or ScrollView;
// the canvas renders in the top safe-area inset with a hairline bottom edge,
// and rows slide beneath it.
//
// The modifier also owns the shared page chrome for template pages:
// - The title is forced inline so it is always visible in the nav bar
//   (a large title would sit under the pinned canvas until scrolled).
// - Trailing nav actions always include a bookmark toggle for the page's
//   catalog entry (`entry` must match an AppEntry name), plus an optional
//   shuffle action when the page has something to randomize.
//
// Keep pinned content compact (~180-240pt) — it permanently owns that
// vertical space. Captions and generated-code boxes belong in the scrolling
// content, not the pinned block.
extension View {
    func pinnedPreview<Canvas: View>(
        entry entryName: String,
        shuffle: (() -> Void)? = nil,
        @ViewBuilder _ canvas: () -> Canvas
    ) -> some View {
        modifier(PinnedPreviewChrome(entryName: entryName, shuffle: shuffle, canvas: canvas()))
    }
}

private struct PinnedPreviewChrome<Canvas: View>: ViewModifier {
    @EnvironmentObject private var pinsStore: PinsStore
    let entryName: String
    let shuffle: (() -> Void)?
    let canvas: Canvas

    private var entry: AppEntry? {
        AppEntry.all.first { $0.name == entryName }
    }

    private var isBookmarked: Bool {
        entry.map { pinsStore.isPinned($0) } ?? false
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                canvas
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    // Matches the page background so the band reads as clear
                    // (no secondary-background tint) while still masking rows
                    // that scroll beneath the canvas.
                    .background(Color(.systemGroupedBackground))
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            // The canvas backdrop extends up behind the nav bar; hiding the
            // bar's own background (as the Shaders page does) keeps the whole
            // top clear instead of showing a second material band.
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if let entry {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            pinsStore.toggle(entry)
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        }
                    }
                }
                if let shuffle {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: shuffle) {
                            Image(systemName: "shuffle")
                        }
                    }
                }
            }
    }
}
