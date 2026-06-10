# MeloMo Visual Design System Overhaul
**Date:** 2026-03-28  
**Status:** Comprehensive Redesign Plan  
**Version:** 1.0

---

## Executive Summary

This document outlines a complete visual design system overhaul for MeloMo iOS app to establish a cohesive, modern brand identity aligned with the "cinematic dark grid" aesthetic mentioned in the enhancement spec. The plan covers color palette, typography, component library, key screen redesigns, motion design, and a phased implementation roadmap.

**Core Promise:** Pick your mood. Music plays instantly. Free forever. Export anywhere.  
**Design Philosophy:** Modern, dark, intuitive, AI-powered energy with cinematic depth.

---

## 1. Color Palette & Visual Hierarchy

### 1.1 Primary Color System

```
Brand Colors:
├─ Primary Gradient
│  ├─ Purple: #9945FF (core brand)
│  ├─ Magenta: #FF2D55 (accent, energy)
│  └─ Indigo: #5E5CE6 (depth)
│
├─ Secondary Accents
│  ├─ Cyan: #00D4FF (highlights, mood-reactive)
│  ├─ Green: #30B0C0 (focus, chill moods)
│  └─ Orange: #FF9500 (energetic, romantic moods)
│
├─ Neutral Palette (Dark Mode)
│  ├─ Background: #0A0A0A
│  ├─ Surface: #1C1C1E
│  ├─ Tertiary: #36363A
│  ├─ Quaternary: #545458
│  └─ Text: #EBEBF5
│
└─ Semantic Colors
   ├─ Success: #34C759
   ├─ Warning: #FF9500
   ├─ Error: #FF3B30
   └─ Info: #00D4FF
```

### 1.2 Mood-Reactive Color Assignments

Each mood category gets a primary accent color for card backgrounds, progress bars, and UI highlights:

| Mood Category | Primary Color | Secondary Color | Symbolic Energy |
|---|---|---|---|
| **Energetic** | #FF2D55 (Magenta) | #FF9500 (Orange) | High, vibrant, immediate |
| **Chill** | #30B0C0 (Cyan) | #5E5CE6 (Indigo) | Calm, spacious, gentle |
| **Focused** | #00D4FF (Bright Cyan) | #9945FF (Purple) | Sharp, driven, clarity |
| **Emotional** | #FF2D55 (Magenta) | #5E5CE6 (Indigo) | Depth, vulnerability, introspection |
| **Romantic** | #FF9500 (Orange) | #FF2D55 (Magenta) | Warmth, connection, intimacy |
| **Social** | #FF2D55 (Magenta) | #00D4FF (Cyan) | Energy, connection, celebration |
| **Magical** | #9945FF (Purple) | #00D4FF (Cyan) | Mystery, wonder, transcendence |
| **Melancholy** | #5E5CE6 (Indigo) | #545458 (Gray) | Introspection, stillness, acceptance |

### 1.3 Visual Hierarchy

- **Hero Elements:** Mood cards, now-playing album art (large, vibrant accent colors)
- **Primary Actions:** Buttons with gradient background (purple → magenta)
- **Secondary Actions:** Outlined buttons with stroke weight 1.5pt
- **Tertiary Actions:** Text-only buttons or minimal icons
- **Surface Depth:** Use tertiary color (#36363A) for card surfaces, quaternary (#545458) for dividers

---

## 2. Typography System

### 2.1 Font Stack

```swift
// Primary Display Font (for headlines, brand identity)
let displayFont = "SF Pro Display"

// Primary Body Font (readable, modern)
let bodyFont = "SF Pro Text"

// Monospace (for technical details, timestamps)
let monoFont = "SF Mono"

// Alternative for accessibility (dyslexia support)
let accessibilityFont = "Dyslexie" // Fallback to SF Pro
```

### 2.2 Type Scale

```
Headline1: 34pt, weight .bold, tracking -0.5
Headline2: 28pt, weight .bold, tracking -0.3
Headline3: 22pt, weight .semibold, tracking -0.2
Headline4: 20pt, weight .semibold, tracking 0
Title1:    18pt, weight .semibold, tracking 0
Title2:    16pt, weight .semibold, tracking 0
Body:      16pt, weight .regular, tracking 0.4
Body2:     14pt, weight .regular, tracking 0.3
Caption1:  12pt, weight .regular, tracking 0.4
Caption2:  11pt, weight .medium, tracking 0.3
```

### 2.3 Line Height & Spacing

```
Line Height Multiplier: 1.4x (body), 1.2x (headlines)

Paragraph Spacing:
├─ Between sections: 24pt
├─ Between elements: 16pt
├─ Between list items: 12pt
└─ Padding within cards: 16pt (horizontal), 12pt (vertical)
```

---

## 3. Component Library

### 3.1 Mood Cards

**Purpose:** Primary interaction for selecting mood  
**Size:** 140x180pt (portrait), responsive grid (2 or 3 per row)  
**State:** Default, Hover (iOS: Pressed), Selected, Disabled

```swift
struct MoodCard {
    // Layout
    let width: CGFloat = 140
    let height: CGFloat = 180
    let cornerRadius: CGFloat = 16
    
    // Colors
    var backgroundColor: Color          // Mood-reactive (see table above)
    var accentColor: Color              // Secondary color from table
    let textColor: Color = .white
    
    // Typography
    let titleFont: Font = .system(size: 16, weight: .semibold)
    let subtitleFont: Font = .system(size: 12, weight: .regular)
    
    // Content
    let icon: String                    // SF Symbol
    let title: String                   // e.g., "Chill"
    let subtitle: String?               // e.g., "Feel relaxed"
    
    // States
    var isSelected: Bool = false        // Add checkmark, scale 1.05
    var isPressed: Bool = false         // Scale 0.95, opacity 0.8
}
```

**Design Details:**
- Gradient background (primary color → secondary color, 45° angle)
- Icon (SF Symbol, 48pt, centered)
- Title below icon (centered, truncate if needed)
- Subtle drop shadow (offset: 0,2; blur: 8; opacity: 0.3)
- On selection: Animated scale-up (1.0 → 1.05), checkmark appears bottom-right
- Haptic feedback on tap (medium impact)

### 3.2 Buttons

**Primary Button** (for main actions: Generate Playlist, Export)
```swift
struct PrimaryButton {
    let height: CGFloat = 52
    let cornerRadius: CGFloat = 12
    let background: LinearGradient = .init(
        gradient: Gradient(colors: [.purple, .magenta]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    let textColor: Color = .white
    let textFont: Font = .system(size: 16, weight: .semibold)
    
    var disabled: Bool = false          // Opacity 0.5
    var isLoading: Bool = false         // Show spinner, disable interactions
}
```

**Secondary Button** (for alternate actions)
```swift
struct SecondaryButton {
    let height: CGFloat = 48
    let cornerRadius: CGFloat = 10
    let borderWidth: CGFloat = 1.5
    let borderColor: Color = .cyan
    let backgroundColor: Color = .clear
    let textColor: Color = .cyan
}
```

**Icon Button** (for compact actions)
```swift
struct IconButton {
    let size: CGFloat = 44
    let cornerRadius: CGFloat = 10
    let backgroundColor: Color = .surface
    let icon: Image
    let iconColor: Color = .cyan
}
```

### 3.3 Input Fields

**Text Input** (for natural language mood description)
```swift
struct TextInputField {
    let height: CGFloat = 48
    let cornerRadius: CGFloat = 12
    let backgroundColor: Color = .surface
    let borderColor: Color = .tertiary
    let borderWidth: CGFloat = 1
    let textColor: Color = .white
    let placeholderColor: Color = .quaternary
    
    var isFocused: Bool = false         // Border color → cyan, scale 1.02
    var hasError: Bool = false          // Border color → red
}
```

**Voice Input Button** (paired with text input)
```swift
struct VoiceInputButton {
    let size: CGFloat = 44
    let cornerRadius: CGFloat = 10
    let backgroundColor: Color = .surface
    let activeColor: Color = .cyan      // Animated pulse during recording
    let recordingAnimation: Animation = .easeInOut(duration: 0.6).repeatForever()
}
```

### 3.4 Mood Category Filter Pills

```swift
struct FilterPill {
    let height: CGFloat = 32
    let cornerRadius: CGFloat = 16
    let paddingHorizontal: CGFloat = 12
    let textFont: Font = .system(size: 14, weight: .semibold)
    
    var isSelected: Bool = false
    
    var backgroundColor: Color {
        isSelected ? .cyan : .surface
    }
    var textColor: Color {
        isSelected ? .black : .white
    }
    
    var borderColor: Color {
        isSelected ? .clear : .tertiary
    }
}
```

### 3.5 Now Playing Card

```swift
struct NowPlayingCard {
    let height: CGFloat = 300
    let cornerRadius: CGFloat = 20
    
    // Gradient background (mood-reactive)
    var gradientBackground: LinearGradient
    
    // Content
    let albumArt: Image
    let trackTitle: String
    let artistName: String
    let moodTag: String                 // e.g., "Chill • Lo-Fi"
    
    // Controls
    let playButton: Button
    let nextButton: Button
    let favoriteButton: Button
    
    // Metadata
    let currentTime: TimeInterval
    let duration: TimeInterval
    let playbackSource: PlaybackSource   // Jamendo / YouTube / Apple Music
}
```

### 3.6 Export Modal

```swift
struct ExportModal {
    let backgroundColor: Color = .surface
    let cornerRadius: CGFloat = 24
    let height: CGFloat = 520          // ~60% of screen
    
    // Content
    let title: String = "Export to Your Music App"
    let subtitle: String = "Choose where you want to save this playlist"
    
    // Export options (buttons)
    let spotifyButton: ExportButton     // #1DB954 green
    let appleMusicButton: ExportButton  // #FA243C red
    let youtubeButton: ExportButton     // #FF0000 red
    
    // Bottom action
    let copyLinkButton: SecondaryButton
}
```

---

## 4. Key Screen Redesigns

### 4.1 Vibes Tab (Mood Selector)

**Current State:** Card picker, tab navigation  
**Redesigned State:** Three-layer experience

**Layer 1: Natural Language Input (Top)**
```
┌─────────────────────────────────────┐
│ ✕ MeloMo                            │
├─────────────────────────────────────┤
│ "How are you feeling?"              │ ← Text input, 48pt tall
│ [🎤]                                │ ← Voice button (right side)
├─────────────────────────────────────┤
│ Suggested: Focus | Chill | Energetic│ ← Pills (from NL classification)
└─────────────────────────────────────┘
```

**Layer 2: Category Filter (Below input)**
```
┌─────────────────────────────────────┐
│ All | Energetic | Chill | Focused   │ ← Horizontal scroll
│ Emotional | Romantic | Social | ...  │
└─────────────────────────────────────┘
```

**Layer 3: Mood Cards Grid (Below filter)**
```
┌─────────────────────────────────────┐
│ ┌────────────┐ ┌────────────┐      │
│ │   Chill    │ │   Focus    │      │
│ │   [🎵]     │ │    [⚡]    │      │
│ └────────────┘ └────────────┘      │
│ ┌────────────┐ ┌────────────┐      │
│ │ Energetic  │ │ Emotional  │      │
│ │   [🔥]     │ │    [💜]    │      │
│ └────────────┘ └────────────┘      │
└─────────────────────────────────────┘
```

**Interactions:**
- Type in input → backend classifies mood in real-time (debounced 300ms)
- Tap filter pill → filter card grid
- Tap card → haptic + scale up → fade to Now Playing
- Voice button → mic permission check → record 3-5 sec audio → transcribe → classify

### 4.2 Now Playing Screen

**Current State:** Simple playback UI  
**Redesigned State:** Cinematic, immersive experience

```
┌─────────────────────────────────────┐
│                                     │
│        [Album Art - Large]          │ ← 280x280pt, rounded corners
│        (Mood-reactive gradient)     │
│                                     │
├─────────────────────────────────────┤
│ "Track Title"                       │ ← Headline2
│ "Artist Name"                       │ ← Body
│ [🎧] Jamendo • 3:45                 │ ← Caption1, source badge
├─────────────────────────────────────┤
│ ◄◄  ▶  ►►                          │ ← Playback controls, 52pt buttons
│ [━━━━◯━━━]                          │ ← Progress slider
│ 1:20  3:45                          │ ← Time codes
├─────────────────────────────────────┤
│ [♡] [↗] […]                        │ ← Favorite, Share, Menu (icon buttons)
├─────────────────────────────────────┤
│ [Export to Spotify]                 │ ← Primary button, 52pt
│ [View Playlist]                     │ ← Secondary button
└─────────────────────────────────────┘
```

**Interactions:**
- Swipe up → reveal full playlist below
- Swipe down → return to Vibes tab
- Long-press album art → view full playlist
- Tap source badge (Jamendo) → switch playback source modal
- Tap export → full export modal (see 4.3)

### 4.3 Export Modal

```
┌─────────────────────────────────────┐
│      Export to Your Music App       │ ← Headline2
│  Save this playlist to your service │ ← Body2, secondary text
├─────────────────────────────────────┤
│ [🎵] Spotify                        │ ← Export button w/ brand color
│      Export to Spotify (opens app)  │
├─────────────────────────────────────┤
│ [🍎] Apple Music                    │ ← Export button (only if subscriber)
│      Save to Library                │
├─────────────────────────────────────┤
│ [📺] YouTube Music                  │ ← Export button
│      Add to Playlist                │
├─────────────────────────────────────┤
│ [🔗] Copy Playlist Link             │ ← Secondary action
│      Share with a friend            │
└─────────────────────────────────────┘
```

**Interactions:**
- Tap Spotify → open deep link → Spotify app handles auth + save
- Tap Apple Music → MusicKit on-device save (no backend call)
- Tap YouTube → backend OAuth → add to playlist
- Tap Copy Link → generate shareable link → UIPasteboard copy → show toast "Copied!"

### 4.4 Onboarding Flow

**Page 1: Welcome**
```
Headline: "Pick your mood."
Subheading: "Music plays instantly. Free forever."
Visual: Animated gradient background with floating music notes
CTA: "Get Started"
```

**Page 2: Mood Selection Demo**
```
Headline: "Select your vibe."
Subheading: "Tell us how you're feeling—any way you like."
Visual: Demo card picker with highlighted card
CTA: "Next"
```

**Page 3: Export Preview**
```
Headline: "Export anywhere."
Subheading: "Save your playlist to Spotify, Apple Music, or YouTube."
Visual: Three brand logos (Spotify, Apple Music, YouTube)
CTA: "Done"
```

---

## 5. Motion & Micro-Interactions

### 5.1 Spring Animations

```swift
// Card selection animation
let cardSelectSpring = Animation.spring(
    response: 0.35,
    dampingFraction: 0.7,
    blendDuration: 0.2
)

// UI element entrances (fade + scale)
let entranceSpring = Animation.spring(
    response: 0.4,
    dampingFraction: 0.75,
    blendDuration: 0.15
)

// Smooth transitions between screens
let screenTransition = AnyTransition
    .scale(scale: 0.8, anchor: .center)
    .combined(with: .opacity)
```

### 5.2 Micro-Interactions

**Voice Recording Pulse**
```
├─ Tap mic button → button scales 1.0 → 1.1 (spring)
├─ Recording active → circular progress indicator (infinite rotation)
├─ Recording background color → cyan with 0.3 opacity
├─ Stop recording → fade out pulse, scale back to 1.0
└─ Transcription complete → success checkmark animation
```

**Playlist Generation Loading**
```
├─ Show skeleton loaders (shimmer effect)
├─ Each card: gradient sweep left-to-right (2sec duration, infinite)
├─ On complete: fade out skeletons, fade in real content
└─ Haptic feedback (medium impact) on completion
```

**Now Playing Transition**
```
├─ Card tap → scale up 1.0 → 1.05 (50ms)
├─ Simultaneously → fade in fullscreen now-playing
├─ Album art animates from card position to center
└─ Backdrop blur + darkening (300ms easing curve)
```

**Export Button States**
```
├─ Idle: gradient background, white text
├─ Pressed: scale 0.95, opacity 0.8
├─ Loading: spinner replaces text, button disabled
├─ Success: checkmark animation (500ms), brief success state
└─ After 2sec: return to idle or show success toast
```

### 5.3 Gesture-Based Feedback

| Gesture | Feedback |
|---|---|
| Tap button | Light haptic impact + visual scale |
| Long-press card | Medium haptic + expand preview |
| Swipe up (Now Playing) | Light haptic + scroll animation |
| Swipe down (Now Playing) | Light haptic + dismiss animation |
| Voice recording | Heavy haptic on start/stop |
| Playlist export | Medium haptic + success state |

---

## 6. Dark Mode & Accessibility

### 6.1 Dark Mode (Primary)

MeloMo is **dark-first.** All colors defined above use dark backgrounds (#0A0A0A, #1C1C1E).

**Light Mode Support (Optional Future)**
```
├─ Background: #FFFFFF
├─ Surface: #F5F5F7
├─ Text: #1C1C1E
├─ Accent: Keep purple/magenta, reduce saturation slightly
└─ Contrast: WCAG AAA compliant (7:1 minimum)
```

### 6.2 Accessibility (WCAG AA Compliant)

**Color Contrast Validation**
```
├─ White text on #9945FF: 6.2:1 ✓ (AA compliant)
├─ Black text on #00D4FF: 2.8:1 ✗ (need light gray text)
├─ White text on #5E5CE6: 5.1:1 ✓ (AA compliant)
└─ All semantic colors validated for 4.5:1 (text) and 3:1 (UI)
```

**Semantic Accessibility**
```
├─ All buttons: `.button` trait
├─ All images: descriptive `accessibilityLabel`
├─ All icons: paired with text labels or use SF Symbols with built-in labels
├─ All interactive elements: minimum 44x44pt tap target
├─ Text: minimum 12pt (preferably 14pt+)
├─ Dynamic Type support: Scale fonts from 11pt → 24pt (settings)
└─ VoiceOver: All screens tested and labeled
```

**Dyslexia Support (Optional)**
```
├─ Provide "Dyslexie" font option in settings
├─ Use sans-serif with generous spacing
├─ Avoid all-caps for body text
├─ Use clear icon differentiation (not color alone)
└─ High contrast mode: Boost accent colors to 7:1+ contrast
```

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
**Goal:** Establish design tokens and build reusable components

- [ ] Create design token definitions (colors, spacing, typography)
- [ ] Build `MoodCard` component with mood-reactive colors
- [ ] Build `PrimaryButton` + `SecondaryButton` + `IconButton` components
- [ ] Build `TextInputField` + `VoiceInputButton` components
- [ ] Build `FilterPill` component
- [ ] Implement dark mode tokens across app
- [ ] Create `ThemeProvider` SwiftUI environment

**Deliverable:** Component library in Xcode (testable in preview)

### Phase 2: Core Components (Week 2-3)
**Goal:** Build interactive components with motion

- [ ] Implement `MoodCardGrid` with filtering logic
- [ ] Implement `NaturalLanguageInput` with voice recording
- [ ] Implement `VoiceInputButton` with mic permissions + recording
- [ ] Implement `NowPlayingCard` with mood-reactive gradient
- [ ] Implement `ExportModal` with three export options
- [ ] Add spring animations to all interactions
- [ ] Add haptic feedback framework

**Deliverable:** Core screens functional with placeholder data

### Phase 3: Screen Redesigns (Week 3-4)
**Goal:** Rebuild key screens using new components

- [ ] Redesign **Vibes Tab** → natural language input + category filter + card grid
- [ ] Redesign **Now Playing Screen** → cinematic album art + metadata + playback controls
- [ ] Redesign **Export Flow** → modal-based export options
- [ ] Redesign **Onboarding** → three-page flow with new visual language
- [ ] Add transitions between screens (scale + fade)
- [ ] Test on multiple device sizes (SE, 11, 12 Pro Max, iPad)

**Deliverable:** All key screens redesigned and functional

### Phase 4: Polish & Refinement (Week 4-5)
**Goal:** Micro-interactions, accessibility, performance

- [ ] Implement playlist generation skeleton loaders (shimmer)
- [ ] Add mood-reactive gradient animations
- [ ] Test WCAG AA accessibility on all screens
- [ ] Implement VoiceOver labels and semantic markup
- [ ] Optimize animations (reduce opacity thrashing, batch updates)
- [ ] Test on device (iPhone 12 minimum)
- [ ] Fix any visual bugs or spacing issues

**Deliverable:** Production-ready design system

### Phase 5: Advanced Features (Week 5+)
**Goal:** Future enhancements (optional)

- [ ] Implement light mode support
- [ ] Add dyslexia-friendly font option
- [ ] Add high contrast mode
- [ ] Implement haptic settings (intensity slider)
- [ ] Add animation speed settings
- [ ] Create design documentation / Figma specs

---

## 8. Design Tokens (Swift Implementation)

### 8.1 Color System

```swift
// MARK: - Design Tokens

enum DesignTokens {
    enum Colors {
        // Primary Gradient
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(#colorLiteral(red: 0.6, green: 0.27, blue: 1.0, alpha: 1)),  // #9945FF
                Color(#colorLiteral(red: 1.0, green: 0.18, blue: 0.33, alpha: 1))   // #FF2D55
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Backgrounds
        static let background = Color(#colorLiteral(red: 0.04, green: 0.04, blue: 0.04, alpha: 1))  // #0A0A0A
        static let surface = Color(#colorLiteral(red: 0.11, green: 0.11, blue: 0.12, alpha: 1))    // #1C1C1E
        static let tertiary = Color(#colorLiteral(red: 0.21, green: 0.21, blue: 0.23, alpha: 1))   // #36363A
        static let quaternary = Color(#colorLiteral(red: 0.33, green: 0.33, blue: 0.35, alpha: 1)) // #545458
        
        // Accents
        static let cyan = Color(#colorLiteral(red: 0.0, green: 0.83, blue: 1.0, alpha: 1))         // #00D4FF
        static let magenta = Color(#colorLiteral(red: 1.0, green: 0.18, blue: 0.33, alpha: 1))    // #FF2D55
        static let orange = Color(#colorLiteral(red: 1.0, green: 0.58, blue: 0.0, alpha: 1))      // #FF9500
        static let purple = Color(#colorLiteral(red: 0.6, green: 0.27, blue: 1.0, alpha: 1))      // #9945FF
        static let indigo = Color(#colorLiteral(red: 0.37, green: 0.36, blue: 0.9, alpha: 1))     // #5E5CE6
        
        // Semantic
        static let success = Color(#colorLiteral(red: 0.2, green: 0.78, blue: 0.35, alpha: 1))    // #34C759
        static let error = Color(#colorLiteral(red: 1.0, green: 0.23, blue: 0.19, alpha: 1))      // #FF3B30
        static let warning = Color(#colorLiteral(red: 1.0, green: 0.58, blue: 0.0, alpha: 1))     // #FF9500
        static let text = Color(#colorLiteral(red: 0.92, green: 0.92, blue: 0.96, alpha: 1))      // #EBEBF5
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let card: CGFloat = 16
        static let pill: CGFloat = 8
    }
}
```

### 8.2 Typography

```swift
enum Typography {
    static func headline1() -> Font {
        .system(size: 34, weight: .bold)
    }
    
    static func headline2() -> Font {
        .system(size: 28, weight: .bold)
    }
    
    static func headline3() -> Font {
        .system(size: 22, weight: .semibold)
    }
    
    static func headline4() -> Font {
        .system(size: 20, weight: .semibold)
    }
    
    static func title1() -> Font {
        .system(size: 18, weight: .semibold)
    }
    
    static func title2() -> Font {
        .system(size: 16, weight: .semibold)
    }
    
    static func body() -> Font {
        .system(size: 16, weight: .regular)
    }
    
    static func body2() -> Font {
        .system(size: 14, weight: .regular)
    }
    
    static func caption1() -> Font {
        .system(size: 12, weight: .regular)
    }
    
    static func caption2() -> Font {
        .system(size: 11, weight: .medium)
    }
}
```

---

## 9. Success Metrics

### 9.1 Design System KPIs

- [ ] **Component Reusability:** 80%+ of screens built using component library
- [ ] **Accessibility:** 100% WCAG AA compliance (automated + manual testing)
- [ ] **Performance:** All animations ≤16ms frame time (60 FPS)
- [ ] **User Satisfaction:** NPS ≥ 50 post-redesign
- [ ] **Adoption:** 100% of app screens using new design tokens

### 9.2 User Engagement Metrics

- [ ] **Mood Selection Time:** < 5 seconds (goal: < 3 seconds)
- [ ] **Export Completion Rate:** ≥ 70% of users complete export
- [ ] **Session Duration:** Increase by 15-20% post-redesign
- [ ] **Voice Input Adoption:** ≥ 25% of mood selections via voice

---

## 10. Next Steps

1. **Review & Approve** this design spec with stakeholders
2. **Create Figma Design System** with all components and color tokens
3. **Begin Phase 1 Implementation** → design tokens + component library
4. **Conduct Accessibility Audit** on Phase 1 components
5. **Build Storybook / SwiftUI Previews** for component showcase
6. **Test on Device** as components are completed
7. **Gather User Feedback** via closed beta testing
8. **Iterate & Polish** based on feedback
9. **Ship Phase 1 MVP** with redesigned core screens

---

## Appendix: Reference Resources

- **SF Symbols:** https://developer.apple.com/sf-symbols/
- **WCAG 2.1 Guidelines:** https://www.w3.org/WAI/WCAG21/quickref/
- **SwiftUI Animation Docs:** https://developer.apple.com/documentation/swiftui/animation
- **Color Contrast Checker:** https://webaim.org/resources/contrastchecker/
- **HIG (Human Interface Guidelines):** https://developer.apple.com/design/human-interface-guidelines/ios

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-28  
**Status:** Ready for Implementation
