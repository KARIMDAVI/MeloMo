import SwiftUI
import MusicKit

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var musicController = MusicController()
    @State private var selectedTab = 0
    @State private var isAuthorized = false
    @State private var currentMoodColors: (primary: Color, secondary: Color)? = nil
    
    var authMethodDisplayName: String {
        switch authManager.authMethod {
        case .apple: return "Apple ID"
        case .google: return "Google"
        case .demo: return "Demo Account"
        case .guest: return "Guest"
        case .none: return "Not signed in"
        }
    }
    
    var body: some View {
        ZStack {
            // Original dark blue background
            Color(red: 0.05, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header
                topHeader
                
                // Main Content
                TabView(selection: $selectedTab) {
                    // Vibes Tab - Always available
                    EnhancedVibesView(onMoodColorChange: { primary, secondary in
                        currentMoodColors = (primary: primary, secondary: secondary)
                    })
                        .environmentObject(musicController)
                        .tabItem {
                            Image(systemName: "music.note")
                            Text("Vibes")
                        }
                        .tag(0)
                    
                    // Stats Tab - Only for signed-in users
                    if authManager.isSignedIn {
                        statsView
                            .tabItem {
                                Image(systemName: "chart.bar")
                                Text("Stats")
                            }
                            .tag(1)
                    } else {
                        signInRequiredView(title: "Stats", icon: "chart.bar", description: "Track your listening habits, achievements, and music journey.")
                            .tabItem {
                                Image(systemName: "chart.bar")
                                Text("Stats")
                            }
                            .tag(1)
                    }
                    
                    // Challenges Tab - Only for signed-in users
                    if authManager.isSignedIn {
                        challengesView
                            .tabItem {
                                Image(systemName: "trophy")
                                Text("Challenges")
                            }
                            .tag(2)
                    } else {
                        signInRequiredView(title: "Challenges", icon: "trophy", description: "Test your music knowledge with trivia challenges")
                            .tabItem {
                                Image(systemName: "trophy")
                                Text("Challenges")
                            }
                            .tag(2)
                    }
                    
                    // Settings Tab - Only for signed-in users
                    if authManager.isSignedIn {
                        settingsView
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .tag(3)
                    } else {
                        signInRequiredView(title: "Settings", icon: "gear", description: "Customize your app experience and manage your account")
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .tag(3)
                    }
                }
                .accentColor(.yellow)
            }
        }
        .onAppear {
            checkAuthorization()
        }
    }
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack {
            // MeloMo "Find your vibe" branding
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("Melo")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Mo")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                Text("Find Your Vibe")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Sign In button
            Button(action: {
                // Show sign in options or navigate to onboarding
                if !authManager.isSignedIn {
                    // Navigate to sign in
                    selectedTab = 3 // Settings tab where sign in is handled
                }
            }) {
                HStack(spacing: 6) {
                    Image("User")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                    
                    if !authManager.isSignedIn {
                        Text("Sign In")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            // Blend with mood colors
            LinearGradient(
                colors: [
                    currentMoodColors?.primary.opacity(0.5) ?? Color(red: 0.05, green: 0.1, blue: 0.2),
                    currentMoodColors?.secondary.opacity(0.3) ?? Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    // MARK: - Current Vibe Card
    private var currentVibeCard: some View {
        HStack(spacing: 16) {
            // Magical stars
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Vibe")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Magical")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Music note
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Vibes View (Always accessible)
    private var vibesView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Mood selection for all users
                VStack(spacing: 16) {
                    Text("Choose Your Vibe")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Mood grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(Array(allMoods.prefix(6)), id: \.id) { mood in
                            MoodCard(mood: mood, isFavorite: false, onTap: {
                                Task {
                                    await musicController.generate(for: mood)
                                }
                            }, onFavorite: {
                                musicController.toggleFavorite(mood)
                            }, onShare: {
                                // Handle share
                            })
                        }
                    }
                    
            if !authManager.isSignedIn {
                Text("Sign in to save your favorite moods and track your music journey")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            } else if let user = authManager.currentUser {
                Text("Welcome back, \(user.name)!")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Stats View (Signed-in users only)
    private var statsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Stats content for signed-in users
                VStack(spacing: 16) {
                    Text("Your Music Journey")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Track your listening habits, achievements, and music journey.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Placeholder for actual stats
                    VStack(spacing: 12) {
                        StatCard(title: "Total Playlists", value: "\(musicController.statistics.totalPlaylistsGenerated)", icon: "music.note")
                        StatCard(title: "Favorite Mood", value: musicController.statistics.favoriteMood?.title ?? "None", icon: "heart")
                        StatCard(title: "Listening Time", value: "2h 30m", icon: "clock")
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Challenges View (Signed-in users only)
    private var challengesView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Challenges content for signed-in users
                VStack(spacing: 16) {
                    Text("Music Challenges")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Test your music knowledge with trivia challenges")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Placeholder for actual challenges
                    VStack(spacing: 12) {
                        ChallengeCard(title: "Genre Master", description: "Identify 10 different music genres", difficulty: "Easy")
                        ChallengeCard(title: "Artist Expert", description: "Name the artist from song snippets", difficulty: "Medium")
                        ChallengeCard(title: "Decade Detective", description: "Guess the decade of popular songs", difficulty: "Hard")
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Settings content
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Account section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.orange)
                            Text("Account")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            if let user = authManager.currentUser {
                                AccountInfoRow(title: "Name", value: user.name)
                                AccountInfoRow(title: "Email", value: user.email)
                                AccountInfoRow(title: "Sign-in Method", value: authMethodDisplayName)
                            } else {
                                AccountInfoRow(title: "Name", value: "Guest User")
                                AccountInfoRow(title: "Email", value: "Not signed in")
                                AccountInfoRow(title: "Sign-in Method", value: "Guest")
                            }
                        }
                        
                        // App Preferences
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.orange)
                                Text("App Preferences")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            // Settings items
                            VStack(spacing: 8) {
                                SettingsRow(
                                    icon: "hand.tap",
                                    title: "Haptic Feedback",
                                    description: "Vibrations on button press",
                                    isOn: false
                                )
                                
                                SettingsRow(
                                    icon: "moon",
                                    title: "Dark Mode",
                                    description: "Use dark theme",
                                    isOn: true
                                )
                                
                                SettingsRow(
                                    icon: "bell",
                                    title: "Notifications",
                                    description: "Get notified about new features",
                                    isOn: true
                                )
                                
                                SettingsRow(
                                    icon: "sunrise",
                                    title: "Daily Vibe Reminders",
                                    description: "Get reminded to find your daily vibe",
                                    isOn: true
                                )
                                
                                SettingsRow(
                                    icon: "chart.bar",
                                    title: "Weekly Recaps",
                                    description: "Get your weekly music journey summary",
                                    isOn: true
                                )
                            }
                        }
                        
                        // Data Management
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(.orange)
                                Text("Data Management")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                SettingsRow(
                                    icon: "chart.bar",
                                    title: "Clear Listening History",
                                    description: "Remove all mood and playlist data",
                                    hasChevron: true
                                )
                                
                                SettingsRow(
                                    icon: "trophy",
                                    title: "Clear Challenge History",
                                    description: "Remove all challenge attempts and achievements",
                                    hasChevron: true
                                )
                            }
                        }
                        
                        // Support
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.orange)
                                Text("Support")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            // Sign out button for testing
                            Button(action: {
                                authManager.signOut()
                                selectedTab = 0 // Go back to Vibes tab
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.square")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .font(.body)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Helper Functions
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "music.note"
        case 1: return "chart.bar"
        case 2: return "trophy"
        case 3: return "gear"
        default: return "circle"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Vibes"
        case 1: return "Stats"
        case 2: return "Challenges"
        case 3: return "Settings"
        default: return ""
        }
    }
    
    private func checkAuthorization() {
        isAuthorized = musicController.isAuthorized
    }
    
    // MARK: - Sign In Required View
    private func signInRequiredView(title: String, icon: String, description: String) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Sign in prompt
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    
                    Text("Sign in to access \(title.lowercased())")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                            Button("Sign In") {
                                // Handle sign in
                                authManager.signInWithDemo() // For demo purposes
                            }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 40)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Challenge Card Component
struct ChallengeCard: View {
    let title: String
    let description: String
    let difficulty: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(difficulty)
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let description: String
    var isOn: Bool? = nil
    var hasChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let isOn = isOn {
                Toggle("", isOn: .constant(isOn))
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            } else if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Account Info Row Component
struct AccountInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Toggle Row Component
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Action Row Component
struct SettingsActionRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? .red : .orange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(isDestructive ? .red : .orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isDestructive ? Color.red.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}