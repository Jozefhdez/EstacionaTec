import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedTab = 1

    var body: some View {
        VStack {
            BottomNavigationBar(selectedTab: $selectedTab)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundApp)
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            MiLugarView()
                .tabItem {
                    Image(systemName: "map")
                    Text("miLugar")
                }
                .tag(0)

            EscanearView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Escanear")
                }
                .tag(1)

            PerfilView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Perfil")
                }
                .tag(2)
        }
        .accentColor(.colorTextos)
    }
}

#Preview {
    ContentView()
}
