import SwiftUI

// Pins a live preview canvas above a scrolling container so controls can be
// adjusted with the preview always in view. Apply to the List or ScrollView;
// the canvas renders in the top safe-area inset on a material backdrop with a
// hairline bottom edge, and rows slide beneath it.
//
// Keep pinned content compact (~180-240pt) — it permanently owns that
// vertical space. Captions and generated-code boxes belong in the scrolling
// content, not the pinned block.
extension View {
    func pinnedPreview<Canvas: View>(@ViewBuilder _ canvas: () -> Canvas) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            canvas()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(.regularMaterial)
                .overlay(alignment: .bottom) {
                    Divider()
                }
        }
    }
}
