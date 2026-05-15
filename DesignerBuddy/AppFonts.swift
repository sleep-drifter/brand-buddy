import SwiftUI
import CoreText

// MARK: - Font API

extension Font {

    /// Returns a NoiGrotesk font that scales with Dynamic Type just like system fonts.
    /// Font.custom(_:size:relativeTo:) is the SwiftUI-native scaling path —
    /// SwiftUI owns the scaling, so no cache, no baked-in sizes, no invalidation needed.
    static func noi(_ style: TextStyle, weight: NoiWeight = .regular) -> Font {
        .custom(weight.fontName, size: style.defaultSize, relativeTo: style)
    }

    static func mono(_ style: TextStyle = .body) -> Font {
        .custom("ChivoMono-Medium", size: style.defaultSize, relativeTo: style)
    }

    enum NoiWeight {
        case regular, medium
        var fontName: String { self == .medium ? "NoiGrotesk-Medium" : "NoiGrotesk-Regular" }
    }
}

// MARK: - Text style helpers

extension Font.TextStyle {
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle:   return 34
        case .title:        return 28
        case .title2:       return 22
        case .title3:       return 20
        case .headline:     return 17
        case .body:         return 17
        case .callout:      return 16
        case .subheadline:  return 15
        case .footnote:     return 13
        case .caption:      return 12
        case .caption2:     return 11
        @unknown default:   return 17
        }
    }
}

// MARK: - Root modifier

struct AppFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.noi(.body))
            .contentMargins(.bottom, 24, for: .scrollContent)
    }
}

extension View {
    func appFonts() -> some View {
        modifier(AppFontModifier())
    }

    func monoFont(_ style: Font.TextStyle = .body) -> some View {
        self.font(.mono(style))
    }
}
