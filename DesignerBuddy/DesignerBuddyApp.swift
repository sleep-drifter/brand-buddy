import SwiftUI
import CoreText

@main
struct DesignerBuddyApp: App {
    @State private var isReady = false

    init() {
        // Run on main synchronously — UIAppearance must be set before first render.
        applyGlobalAppearance()
        // Font registration and AppEntry warm-up can happen off the main thread.
        // SplashView uses system fonts only; the 0.6s delay gives ample time for
        // fonts to be registered before ContentView fades in.
        DispatchQueue.global(qos: .userInitiated).async {
            registerFonts()
            // Force AppEntry.all static-let initialization: generates UUIDs,
            // runs all lowercased() calls, and warms ICU Unicode tables —
            // so the first search keystroke is instant.
            _ = AppEntry.all
        }
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
                // Pre-warm the keyboard during the splash so the first search tap
                // doesn't hitch 5-10s loading iOS keyboard ML/layout resources.
                // becomeFirstResponder + immediate resign loads resources without
                // animating the keyboard on screen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    prewarmKeyboard()
                }
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
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
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

private func applyGlobalAppearance() {
    // UIFontMetrics.scaledFont(for:) produces a font that is correctly sized for
    // the current Dynamic Type category. UIAppearance is set once at launch, so
    // we read the current category here; the font size is correct on first render.
    // (Nav bar appearance is reset by the OS on content-size-category change anyway.)
    let metrics17 = UIFontMetrics(forTextStyle: .body)
    let metrics34 = UIFontMetrics(forTextStyle: .largeTitle)

    // Bar button items
    if let base17 = UIFont(name: "NoiGrotesk-Medium", size: 17) {
        let scaled = metrics17.scaledFont(for: base17)
        let attrs: [NSAttributedString.Key: Any] = [.font: scaled]
        UIBarButtonItem.appearance().setTitleTextAttributes(attrs, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(attrs, for: .highlighted)
    }
    // Nav bar inline + large title
    if let base17 = UIFont(name: "NoiGrotesk-Medium", size: 17),
       let base34 = UIFont(name: "NoiGrotesk-Medium", size: 34) {
        let scaled17 = metrics17.scaledFont(for: base17)
        let scaled34 = metrics34.scaledFont(for: base34)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes      = [.font: scaled17]
        navAppearance.largeTitleTextAttributes = [.font: scaled34]
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance
    }
}

// Force the iOS keyboard stack to load its ML models and layout data during
// the splash, before the user can tap a search field. Call-and-resign pattern
// loads resources without animating the keyboard onscreen.
private func prewarmKeyboard() {
    guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene }).first,
          let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
    else { return }
    let field = UITextField(frame: .zero)
    field.isHidden = true
    window.addSubview(field)
    field.becomeFirstResponder()
    field.resignFirstResponder()
    field.removeFromSuperview()
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
