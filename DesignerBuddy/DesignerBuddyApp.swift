import SwiftUI
import CoreText

@main
struct DesignerBuddyApp: App {
    @State private var isReady = false

    init() {
        registerFonts()
        warmFontCache()
        applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .appFonts()
                    .opacity(isReady ? 1 : 0)

                if !isReady {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isReady = true
                    }
                }
            }
        }
    }
}

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(.tint)
                    .scaleEffect(pulse ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)

                Text("Designer Buddy")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .onAppear { pulse = true }
    }
}

// Pre-populate the font cache on a background thread during the splash delay
// so all Text views get cached Font objects on first render.
private func warmFontCache() {
    DispatchQueue.global(qos: .userInitiated).async {
        let styles: [Font.TextStyle] = [
            .largeTitle, .title, .title2, .title3,
            .headline, .body, .callout, .subheadline,
            .footnote, .caption, .caption2
        ]
        for style in styles {
            _ = Font.noi(style, weight: .regular)
            _ = Font.noi(style, weight: .medium)
        }
    }
}

private func applyGlobalAppearance() {
    // Apply NoiGrotesk to UIKit nav bar button items (plain text buttons in .toolbar)
    if let regular = UIFont(name: "NoiGrotesk-Regular", size: 17) {
        let attrs: [NSAttributedString.Key: Any] = [.font: regular]
        UIBarButtonItem.appearance().setTitleTextAttributes(attrs, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(attrs, for: .highlighted)
    }
    // Nav bar large + inline title
    if let medium = UIFont(name: "NoiGrotesk-Medium", size: 17),
       let large  = UIFont(name: "NoiGrotesk-Medium", size: 34) {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes      = [.font: medium]
        navAppearance.largeTitleTextAttributes = [.font: large]
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance
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
