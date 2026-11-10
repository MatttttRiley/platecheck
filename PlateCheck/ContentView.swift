import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VanityCheckView()
                .tabItem { Label("Vanity", systemImage: "textformat.abc") }

            LookupView()
                .tabItem { Label("Lookup", systemImage: "car.fill") }
        }
    }
}

#Preview {
    ContentView()
}
