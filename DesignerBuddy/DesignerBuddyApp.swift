import SwiftUI
import CoreText

@main
struct DesignerBuddyApp: App {
    init() {
        registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFonts()
        }
    }
}

private func registerFonts() {
    let fonts: [(String, String)] = [
        ("NoiGrotesk-Regular", "otf"),
        ("NoiGrotesk-Medium", "otf"),
        ("ChivoMono-VariableFont_wght", "ttf"),
    ]
    for (name, ext) in fonts {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { continue }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
