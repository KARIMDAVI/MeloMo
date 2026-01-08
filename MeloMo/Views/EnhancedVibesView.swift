import SwiftUI
import MusicKit

struct EnhancedVibesView: View {
    @EnvironmentObject private var musicController: MusicController
    @State private var selectedMood: EnhancedMood?
    @State private var isPlaying = false
    @State private var currentTrack: MusicTrack?
    @State private var showVibeCard = false
    @State private var selectedCategory: MoodCategory? = nil
    @State private var searchText = ""
    
    let onMoodColorChange: (Color, Color) -> Void
    
    var filteredMoods: [EnhancedMood] {
        var moods = enhancedMoods
        
        if let category = selectedCategory {
            switch category {
            case .energetic:
                moods = moods.filter { $0.category == .energetic }
            case .chill, .relaxed:
                moods = moods.filter { $0.category == .chill || $0.category == .relaxed }
            case .emotional, .melancholy:
                moods = moods.filter { $0.category == .emotional || $0.category == .melancholy }
            default:
                moods = moods.filter { $0.category == category }
            }
        }
        
        if !searchText.isEmpty {
            moods = moods.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.seeds.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return moods
    }
    
    var body: some View {
        ZStack {
            // Dynamic background based on selected mood
            if let mood = selectedMood {
                LinearGradient(
                    colors: [
                        mood.backgroundColor.primary.opacity(0.3),
                        mood.backgroundColor.secondary.opacity(0.2),
                        Color(red: 0.05, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: selectedMood?.id)
            } else {
                Color(red: 0.05, green: 0.1, blue: 0.2)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header with search and categories
                headerSection
                
                // Floating Provider Selection Bar
                floatingProviderBar
                    .padding(.top, 20) // Add space between search bar and provider bar
                
                // Moods grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
                        ForEach(filteredMoods) { mood in
                            EnhancedMoodCard(
                                mood: mood,
                                isSelected: selectedMood?.id == mood.id,
                                onTap: {
                                    selectMood(mood)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20) // Space below floating bar
                    .padding(.bottom, 100) // Space for music player
                }
            }
            
            // Music Player Bar
            if let track = currentTrack {
                musicPlayerBar(track: track)
            }
            
            // Vibe Card Share Sheet
            if showVibeCard, let mood = selectedMood {
                VibeCardShareSheet(
                    mood: mood,
                    topTracks: getTopTracks(for: mood),
                    isPresented: $showVibeCard
                )
            }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            // Update track info and playback state for Apple Music
            if musicController.provider == .appleMusic {
                if let realTrack = musicController.currentPlayingTrack {
                    currentTrack = realTrack
                }
                isPlaying = musicController.isPlaying
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Category Tabs
            categoryTabsSection
            
            // Search bar with liquid glass
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search moods...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .liquidGlass(cornerRadius: 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8) // Add bottom padding to header
        .background(
            // Blend with mood colors
            LinearGradient(
                colors: [
                    selectedMood?.backgroundColor.primary.opacity(0.4) ?? Color.clear,
                    selectedMood?.backgroundColor.secondary.opacity(0.3) ?? Color.clear,
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Category Tabs Section
    private var categoryTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Category
                CategoryTab(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // Main Categories
                CategoryTab(
                    title: "Energetic",
                    isSelected: selectedCategory == .energetic,
                    action: { selectedCategory = .energetic }
                )
                
                CategoryTab(
                    title: "Relaxed",
                    isSelected: selectedCategory == .chill,
                    action: { selectedCategory = .chill }
                )
                
                CategoryTab(
                    title: "Emotional",
                    isSelected: selectedCategory == .emotional || selectedCategory == .melancholy,
                    action: { 
                        // Toggle between emotional and melancholy
                        selectedCategory = selectedCategory == .emotional ? .melancholy : .emotional
                    }
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Floating Provider Bar
    private var floatingProviderBar: some View {
        HStack(spacing: 30) {
            // Apple Music
            Button(action: {
                musicController.provider = .appleMusic
                Haptics.tap()
                regeneratePlaylistIfNeeded()
            }) {
                Image("Applemusic")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .scaleEffect(musicController.provider == .appleMusic ? 1.1 : 1.0)
                    .opacity(musicController.provider == .appleMusic ? 1.0 : 0.7)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Spotify
            Button(action: {
                musicController.provider = .spotify
                Haptics.tap()
                regeneratePlaylistIfNeeded()
            }) {
                Image("spotify")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .scaleEffect(musicController.provider == .spotify ? 1.1 : 1.0)
                    .opacity(musicController.provider == .spotify ? 1.0 : 0.7)
            }
            .buttonStyle(PlainButtonStyle())
            
            // YouTube Music
            Button(action: {
                musicController.provider = .youtubeMusic
                Haptics.tap()
                regeneratePlaylistIfNeeded()
            }) {
                Image("YTMusic")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .scaleEffect(musicController.provider == .youtubeMusic ? 1.1 : 1.0)
                    .opacity(musicController.provider == .youtubeMusic ? 1.0 : 0.7)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 40)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: musicController.provider)
    }
    
    // MARK: - Music Player Bar
    private func musicPlayerBar(track: MusicTrack) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 16) {
                // Track artwork
                Group {
                    if let artworkURL = track.artworkURL {
                        AsyncImage(url: artworkURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .onAppear {
                                        print("✅ ARTWORK LOADED SUCCESSFULLY!")
                                    }
                            case .failure(let error):
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.3))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                            Text("Failed")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white)
                                        }
                                    )
                                    .onAppear {
                                        print("❌ ARTWORK LOADING FAILED: \(error.localizedDescription)")
                                        print("❌ URL WAS: \(artworkURL.absoluteString)")
                                    }
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.3))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                                .tint(.white)
                                            Text("Loading")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white)
                                        }
                                    )
                                    .onAppear {
                                        print("🔄 LOADING ARTWORK FROM: \(artworkURL.absoluteString)")
                                    }
                            @unknown default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    )
                            }
                        }
                    } else {
                        // No artwork URL available
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.3))
                            .overlay(
                                VStack(spacing: 2) {
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    Text("No Art")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                }
                            )
                            .onAppear {
                                print("⚠️ NO ARTWORK URL AVAILABLE FOR TRACK: \(track.title)")
                            }
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(.black)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 12) {
                    // Previous button
                    Button(action: { 
                        Task {
                            await musicController.skipToPrevious()
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    // Play/Pause button
                    Button(action: { togglePlayPause() }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    // Next button
                    Button(action: { 
                        Task {
                            await musicController.skipToNext()
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    // Dynamic provider button
                    Button(action: { openCurrentProvider() }) {
                        Image(getCurrentProviderImageName())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    
                    // Share button
                    Button(action: { showVibeCard = true }) {
                        Image("Share")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helper Functions
    private func selectMood(_ mood: EnhancedMood) {
        Haptics.moodSelected()
        selectedMood = mood
        
        // Update parent view with mood colors
        onMoodColorChange(mood.backgroundColor.primary, mood.backgroundColor.secondary)
        
        Task {
            // Convert EnhancedMood to regular Mood for compatibility
            let regularMood = Mood(
                emoji: mood.emoji,
                imageName: mood.imageName,
                title: mood.title,
                description: mood.description,
                seeds: mood.seeds,
                energy: mood.energy,
                category: mood.category,
                popularity: mood.popularity
            )
            
            await musicController.generate(for: regularMood)
            
            // Check if music generation was successful and update UI accordingly
            if musicController.lastGeneratedLink != nil {
                // For Apple Music, try to get the actual playing track
                if musicController.provider == .appleMusic {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Try to get real track info from Apple Music player
                        if let realTrack = musicController.currentPlayingTrack {
                            currentTrack = realTrack
                        } else {
                            // Fallback to placeholder with stored artwork
                            currentTrack = MusicTrack(
                                id: UUID().uuidString,
                                title: mood.title + " Playlist",
                                artist: "Generated for your mood",
                                album: "Apple Music",
                                artworkURL: musicController.currentTrackArtworkURL,
                                duration: 180,
                                energy: mood.energy,
                                genre: mood.seeds.first,
                                mood: mood.title
                            )
                        }
                        isPlaying = musicController.isPlaying
                    }
                } else {
                    // For other providers, create a placeholder track
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        currentTrack = MusicTrack(
                            id: UUID().uuidString,
                            title: mood.title + " Playlist",
                            artist: "Generated for your mood",
                            album: musicController.provider.rawValue,
                            artworkURL: nil,
                            duration: 180,
                            energy: mood.energy,
                            genre: mood.seeds.first,
                            mood: mood.title
                        )
                    }
                }
            }
        }
    }
    
    private func togglePlayPause() {
        Haptics.buttonPress()
        Task {
            do {
                let currentlyPlaying = musicController.isPlaying
                
                if currentlyPlaying {
                    // Currently playing, so pause
                    ApplicationMusicPlayer.shared.pause()
                    DispatchQueue.main.async {
                        isPlaying = false
                    }
                } else {
                    // Currently paused, so play
                    try await ApplicationMusicPlayer.shared.play()
                    DispatchQueue.main.async {
                        isPlaying = true
                    }
                }
            } catch {
                print("Playback control error: \(error)")
                // Reset state on error
                DispatchQueue.main.async {
                    isPlaying = musicController.isPlaying
                }
            }
        }
    }
    
    private func openInAppleMusic() {
        Haptics.tap()
        if let lastLink = musicController.lastGeneratedLink,
           case .appleMusic(let url) = lastLink {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInSpotify() {
        Haptics.tap()
        if let lastLink = musicController.lastGeneratedLink,
           case .spotify(let url) = lastLink {
            UIApplication.shared.open(url)
        }
    }
    
    private func openCurrentProvider() {
        switch musicController.provider {
        case .appleMusic:
            openInAppleMusic()
        case .spotify:
            openInSpotify()
        case .youtubeMusic:
            openInYouTubeMusic()
        }
    }
    
    private func openInYouTubeMusic() {
        Haptics.tap()
        if let lastLink = musicController.lastGeneratedLink,
           case .youtubeMusic(let url) = lastLink {
            UIApplication.shared.open(url)
        }
    }
    
    private func getCurrentProviderImageName() -> String {
        switch musicController.provider {
        case .appleMusic:
            return "Applemusic"
        case .spotify:
            return "spotify"
        case .youtubeMusic:
            return "YTMusic"
        }
    }
    
    private func regeneratePlaylistIfNeeded() {
        if let currentMood = musicController.currentMood {
            Task {
                await musicController.generate(for: currentMood)
            }
        }
    }
    
    
    private func getTopTracks(for mood: EnhancedMood) -> [MusicTrack] {
        // Return top 3 trendy tracks for each specific mood
        switch mood.title {
        case "Happy":
            return [
                MusicTrack(id: "1", title: "Good 4 U", artist: "Olivia Rodrigo", album: "SOUR", artworkURL: nil, duration: 178, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "2", title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", artworkURL: nil, duration: 200, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "3", title: "Levitating", artist: "Dua Lipa", album: "Future Nostalgia", artworkURL: nil, duration: 203, energy: mood.energy, genre: "Pop", mood: mood.title)
            ]
        case "Chill":
            return [
                MusicTrack(id: "1", title: "Sunflower", artist: "Post Malone & Swae Lee", album: "Spider-Verse Soundtrack", artworkURL: nil, duration: 158, energy: mood.energy, genre: "Hip-Hop", mood: mood.title),
                MusicTrack(id: "2", title: "Stay", artist: "Rihanna", album: "ANTI", artworkURL: nil, duration: 247, energy: mood.energy, genre: "R&B", mood: mood.title),
                MusicTrack(id: "3", title: "Golden", artist: "Harry Styles", album: "Fine Line", artworkURL: nil, duration: 208, energy: mood.energy, genre: "Pop", mood: mood.title)
            ]
        case "Hype":
            return [
                MusicTrack(id: "1", title: "Industry Baby", artist: "Lil Nas X & Jack Harlow", album: "MONTERO", artworkURL: nil, duration: 212, energy: mood.energy, genre: "Hip-Hop", mood: mood.title),
                MusicTrack(id: "2", title: "Heat Waves", artist: "Glass Animals", album: "Dreamland", artworkURL: nil, duration: 238, energy: mood.energy, genre: "Indie", mood: mood.title),
                MusicTrack(id: "3", title: "Don't Start Now", artist: "Dua Lipa", album: "Future Nostalgia", artworkURL: nil, duration: 183, energy: mood.energy, genre: "Pop", mood: mood.title)
            ]
        case "Focus":
            return [
                MusicTrack(id: "1", title: "Weightless", artist: "Marconi Union", album: "Ambient", artworkURL: nil, duration: 480, energy: mood.energy, genre: "Ambient", mood: mood.title),
                MusicTrack(id: "2", title: "Clair de Lune", artist: "Claude Debussy", album: "Classical", artworkURL: nil, duration: 300, energy: mood.energy, genre: "Classical", mood: mood.title),
                MusicTrack(id: "3", title: "Lofi Study", artist: "ChilledCow", album: "Study Beats", artworkURL: nil, duration: 240, energy: mood.energy, genre: "Lo-Fi", mood: mood.title)
            ]
        case "Heartbreak":
            return [
                MusicTrack(id: "1", title: "Someone Like You", artist: "Adele", album: "21", artworkURL: nil, duration: 285, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "2", title: "All Too Well", artist: "Taylor Swift", album: "Red (Taylor's Version)", artworkURL: nil, duration: 329, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "3", title: "Somebody That I Used to Know", artist: "Gotye", album: "Making Mirrors", artworkURL: nil, duration: 244, energy: mood.energy, genre: "Indie", mood: mood.title)
            ]
        case "Sunny":
            return [
                MusicTrack(id: "1", title: "Here Comes the Sun", artist: "The Beatles", album: "Abbey Road", artworkURL: nil, duration: 185, energy: mood.energy, genre: "Rock", mood: mood.title),
                MusicTrack(id: "2", title: "Walking on Sunshine", artist: "Katrina and the Waves", album: "Walking on Sunshine", artworkURL: nil, duration: 239, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "3", title: "Good as Hell", artist: "Lizzo", album: "Cuz I Love You", artworkURL: nil, duration: 159, energy: mood.energy, genre: "Pop", mood: mood.title)
            ]
        case "Moody":
            return [
                MusicTrack(id: "1", title: "Billie Jean", artist: "Michael Jackson", album: "Thriller", artworkURL: nil, duration: 294, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "2", title: "Bad Guy", artist: "Billie Eilish", album: "WHEN WE ALL FALL ASLEEP", artworkURL: nil, duration: 194, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "3", title: "Midnight City", artist: "M83", album: "Hurry Up, We're Dreaming", artworkURL: nil, duration: 244, energy: mood.energy, genre: "Electronic", mood: mood.title)
            ]
        default:
            // Generic trendy tracks for other moods
            return [
                MusicTrack(id: "1", title: "As It Was", artist: "Harry Styles", album: "Harry's House", artworkURL: nil, duration: 167, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "2", title: "Anti-Hero", artist: "Taylor Swift", album: "Midnights", artworkURL: nil, duration: 200, energy: mood.energy, genre: "Pop", mood: mood.title),
                MusicTrack(id: "3", title: "Flowers", artist: "Miley Cyrus", album: "Endless Summer Vacation", artworkURL: nil, duration: 200, energy: mood.energy, genre: "Pop", mood: mood.title)
            ]
        }
    }
}

// MARK: - Enhanced Mood Card
struct EnhancedMoodCard: View {
    let mood: EnhancedMood
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Haptics.moodSelected()
            onTap()
        }) {
            VStack(spacing: 12) {
                // Mood icon and emoji
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    mood.backgroundColor.primary,
                                    mood.backgroundColor.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(mood.accentColor.primary, lineWidth: 2)
                        )
                        .shadow(color: mood.accentColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(mood.emoji)
                        .font(.system(size: 28))
                }
                
                // Mood title
                Text(mood.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Music description
                Text(mood.musicDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Energy indicator
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < Int(mood.energy * 5) ? mood.accentColor.primary : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                mood.backgroundColor.primary.opacity(0.2),
                                mood.backgroundColor.secondary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? mood.accentColor.primary : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? mood.accentColor.primary.opacity(0.3) : Color.black.opacity(0.2),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .liquidGlassCard(cornerRadius: 20, isSelected: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.yellow : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.yellow : Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vibe Card Share Sheet
struct VibeCardShareSheet: View {
    let mood: EnhancedMood
    let topTracks: [MusicTrack]
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Share card
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Share Your Vibe")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                // Vibe card content
                VStack(spacing: 16) {
                    // Mood info
                    HStack(spacing: 16) {
                        Text(mood.emoji)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mood.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(mood.musicDescription)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    // Top tracks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Tracks")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(topTracks.prefix(3), id: \.id) { track in
                            HStack {
                                Text("\(topTracks.firstIndex(where: { $0.id == track.id })! + 1)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(.black)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mood.backgroundColor.primary.opacity(1),
                                    mood.backgroundColor.secondary.opacity(1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(mood.accentColor.primary.opacity(1), lineWidth: 1)
                        )
                )
                
                // Share button
                Button(action: { 
                    shareVibeCard()
                }) {
                    Text("Share Vibe Card")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                mood.backgroundColor.primary.opacity(0.4),
                                mood.backgroundColor.secondary.opacity(0.3),
                                Color(red: 0.05, green: 0.1, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(mood.accentColor.primary.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }
    
    private func shareVibeCard() {
        Haptics.successPattern()
        
        // Create the vibe card as an image
        let vibeCardView = createShareableVibeCard()
        let renderer = ImageRenderer(content: vibeCardView)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            let activityController = UIActivityViewController(
                activityItems: [image],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityController, animated: true)
            }
        }
    }
    
    private func createShareableVibeCard() -> some View {
        VStack(spacing: 16) {
            // Mood info
            HStack(spacing: 16) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(mood.musicDescription)
                        .font(.caption)
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            
            // Top tracks
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Tracks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(topTracks.prefix(3), id: \.id) { track in
                    HStack {
                        Text("\(topTracks.firstIndex(where: { $0.id == track.id })! + 1)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // MeloMo branding
            Text("Generated By: MeloMo - Find Your Vibe! 🎶")
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            mood.backgroundColor.primary.opacity(1),
                            mood.backgroundColor.secondary.opacity(1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(mood.accentColor.primary.opacity(1), lineWidth: 1)
                )
        )
        .frame(width: 320, height: 400)
    }
}

#Preview {
    EnhancedVibesView(onMoodColorChange: { _, _ in })
        .environmentObject(MusicController())
        .preferredColorScheme(.dark)
}



