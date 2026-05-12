import SwiftUI

// MARK: - Font Constants

extension Font {

    // Noi Grotesk — default app font
    // Weight: use .medium for anything semibold or heavier, .regular otherwise.
    static func noi(_ style: TextStyle, weight: NoiWeight = .regular) -> Font {
        .custom(weight.fontName, size: style.defaultSize, relativeTo: style)
    }

    // Chivo Mono — monospaced token / code display only
    static func mono(_ style: TextStyle = .body) -> Font {
        .custom("ChivoMono-Medium", size: style.defaultSize, relativeTo: style)
    }

    enum NoiWeight {
        case regular, medium
        var fontName: String {
            self == .medium ? "NoiGrotesk-Medium" : "NoiGrotesk-Regular"
        }
    }
}

// Maps SwiftUI text styles to their default point sizes (Large size category)
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

// MARK: - Root Font Modifier

struct AppFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.noi(.body))
    }
}

extension View {
    func appFonts() -> some View {
        modifier(AppFontModifier())
    }
}

// MARK: - Monospaced Convenience

extension View {
    /// Apply Chivo Mono at the given text style. Replaces .
    func monoFont(_ style: Font.TextStyle = .body) -> some View {
        self.font(.mono(style))
    }
}
