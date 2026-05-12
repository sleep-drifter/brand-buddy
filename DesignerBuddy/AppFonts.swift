import SwiftUI
import CoreText

// MARK: - Font API

extension Font {

    static func noi(_ style: TextStyle, weight: NoiWeight = .regular) -> Font {
        let base = noiUIFont(postScriptName: weight.fontName, size: style.defaultSize)
        let scaled = UIFontMetrics(forTextStyle: style.uiTextStyle).scaledFont(for: base)
        return Font(scaled)
    }

    static func mono(_ style: TextStyle = .body) -> Font {
        .custom("ChivoMono-Medium", size: style.defaultSize, relativeTo: style)
    }

    enum NoiWeight {
        case regular, medium
        var fontName: String { self == .medium ? "NoiGrotesk-Medium" : "NoiGrotesk-Regular" }
    }
}

// Builds a UIFont for Noi Grotesk with the OpenType features that match our web stack:
// font-feature-settings: "kern","liga","calt","ss02","ss03","ss11","ss12"
private func noiUIFont(postScriptName: String, size: CGFloat) -> UIFont {
    let features: [[String: Any]] = [
        [kCTFontOpenTypeFeatureTag as String: "kern", kCTFontOpenTypeFeatureValue as String: 1],
        [kCTFontOpenTypeFeatureTag as String: "liga", kCTFontOpenTypeFeatureValue as String: 1],
        [kCTFontOpenTypeFeatureTag as String: "calt", kCTFontOpenTypeFeatureValue as String: 1],
        [kCTFontOpenTypeFeatureTag as String: "ss02", kCTFontOpenTypeFeatureValue as String: 1],
        [kCTFontOpenTypeFeatureTag as String: "ss03", kCTFontOpenTypeFeatureValue as String: 1],
        [kCTFontOpenTypeFeatureTag as String: "ss11", kCTFontOpenTypeFeatureValue as String: 1],
        [kCTFontOpenTypeFeatureTag as String: "ss12", kCTFontOpenTypeFeatureValue as String: 1],
    ]
    let descriptor = UIFontDescriptor(fontAttributes: [
        .name: postScriptName,
        UIFontDescriptor.AttributeName(rawValue: kCTFontFeatureSettingsAttribute as String): features,
    ])
    return UIFont(descriptor: descriptor, size: size)
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

    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle:   return .largeTitle
        case .title:        return .title1
        case .title2:       return .title2
        case .title3:       return .title3
        case .headline:     return .headline
        case .body:         return .body
        case .callout:      return .callout
        case .subheadline:  return .subheadline
        case .footnote:     return .footnote
        case .caption:      return .caption1
        case .caption2:     return .caption2
        @unknown default:   return .body
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
