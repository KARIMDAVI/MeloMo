import SwiftUI
import MusicKit

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var musicController = MusicController()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            ThemeColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Content
                TabView(selection: $selectedTab) {
                    VibesView()
                        .environmentObject(musicController)
                        .tabItem { 
                            Label("Vibes", systemImage: "music.note")
                        }
                        .tag(0)

                    LibraryView()
                        .environmentObject(musicController)
                        .tabItem { 
                            Label("Library", systemImage: "square.stack")
                        }
                        .tag(1)

                    if authManager.isSignedIn {
                        StatsView()
                            .environmentObject(musicController)
                            .tabItem { 
                                Label("Stats", systemImage: "chart.bar")
                            }
                            .tag(2)
                    } else {
                        SignInRequiredView(title: "Stats", icon: "chart.bar", description: "Track your mood streaks, favorite vibes, and playlist history.")
                            .tabItem { 
                                Label("Stats", systemImage: "chart.bar")
                            }
                            .tag(2)
                    }

                    SettingsView()
                        .environmentObject(authManager)
                        .tabItem { 
                            Label("Profile", systemImage: "person.circle")
                        }
                        .tag(3)
                }
                .accentColor(ThemeColors.primaryAccent)
            }
        }
    }
}

