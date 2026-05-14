import SwiftUI
import CoreText

// MARK: - Font API

extension Font {

    static func noi(_ style: TextStyle, weight: NoiWeight = .regular) -> Font {
        NoiFontCache.shared.swiftUIFont(style: style, weight: weight)
    }

    static func mono(_ style: TextStyle = .body) -> Font {
        .custom("ChivoMono-Medium", size: style.defaultSize, relativeTo: style)
    }

    enum NoiWeight {
        case regular, medium
        var fontName: String { self == .medium ? "NoiGrotesk-Medium" : "NoiGrotesk-Regular" }
    }
}

// MARK: - Cache

private final class NoiFontCache: @unchecked Sendable {
    static let shared = NoiFontCache()

    private init() {
        // Clear cached Font objects whenever the user changes Dynamic Type —
        // UIFontMetrics.scaledFont(for:) bakes the current size, so stale
        // entries would serve wrong sizes after a settings change.
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.lock.lock()
            self?.cache.removeAll()
            self?.lock.unlock()
        }
    }

    private struct Key: Hashable {
        let style: Font.TextStyle
        let weight: Font.NoiWeight
        static func == (lhs: Key, rhs: Key) -> Bool { lhs.style == rhs.style && lhs.weight == rhs.weight }
        func hash(into hasher: inout Hasher) {
            hasher.combine(style)
            hasher.combine(weight == .medium)
        }
    }

    private let lock = NSLock()
    private var cache: [Key: Font] = [:]

    func swiftUIFont(style: Font.TextStyle, weight: Font.NoiWeight) -> Font {
        let key = Key(style: style, weight: weight)
        lock.lock()
        if let hit = cache[key] { lock.unlock(); return hit }
        lock.unlock()
        let uiFont = makeUIFont(postScriptName: weight.fontName, size: style.defaultSize)
        let scaled = UIFontMetrics(forTextStyle: style.uiTextStyle).scaledFont(for: uiFont)
        let font = Font(scaled)
        lock.lock(); cache[key] = font; lock.unlock()
        return font
    }

    private func makeUIFont(postScriptName: String, size: CGFloat) -> UIFont {
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
