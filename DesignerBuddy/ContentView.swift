import SwiftUI

struct ContentView: View {
    @StateObject private var pinsStore = PinsStore()

    var body: some View {
        HomeView()
            .environmentObject(pinsStore)
    }
}

#Preview {
    ContentView()
}
