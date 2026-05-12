import SwiftUI
import CoreText

@main
struct DesignerBuddyApp: App {
    @State private var isReady = false

    init() {
        registerFonts()
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
