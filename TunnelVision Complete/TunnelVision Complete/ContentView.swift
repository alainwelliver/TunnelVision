import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @EnvironmentObject var transitVM: TransitViewModel

    var body: some View {
        if navigationVM.showLanding {
            LandingView()
        } else {
            TabView(selection: $navigationVM.selectedTab) {
                SearchView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .tag(0)

                NavigationContainerView()
                    .tabItem {
                        Image(systemName: "arrow.triangle.swap")
                        Text("Nav")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .tint(Color(hex: "#17c964"))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationViewModel())
        .environmentObject(TransitViewModel())
}
