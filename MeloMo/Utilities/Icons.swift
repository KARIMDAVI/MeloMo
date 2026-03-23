// Icons.swift
// Single source of truth for all FontAwesome icons used in MeloMo.
// Why: prevents magic strings scattered through views — one rename fixes everything.
// Note: thii/FontAwesome.swift uses FA5 naming (e.g. .userCircle, not .circleUser).
import FontAwesome
import SwiftUI

// MARK: - SwiftUI Font bridge
// thii/FontAwesome.swift only ships UIFont.fontAwesome — add the SwiftUI equivalent here
// so every view can use Font.fontAwesome(ofSize:style:) without UIKit imports.
// UIFont is toll-free bridged to CTFont, which Font(CTFont) accepts since iOS 13.
extension Font {
    static func fontAwesome(ofSize size: CGFloat, style: FontAwesomeStyle) -> Font {
        Font(UIFont.fontAwesome(ofSize: size, style: style) as CTFont)
    }
}

// MARK: - Icon constants

enum Icons {
    // Tabs
    static let vibes    = String.fontAwesomeIcon(name: .music)
    static let library  = String.fontAwesomeIcon(name: .layerGroup)
    static let stats    = String.fontAwesomeIcon(name: .chartBar)
    static let profile  = String.fontAwesomeIcon(name: .userCircle)    // FA5: userCircle (not circleUser)

    // Playback
    static let play     = String.fontAwesomeIcon(name: .playCircle)    // FA5: playCircle
    static let pause    = String.fontAwesomeIcon(name: .pauseCircle)   // FA5: pauseCircle
    static let skipNext = String.fontAwesomeIcon(name: .stepForward)   // FA5: stepForward
    static let skipPrev = String.fontAwesomeIcon(name: .stepBackward)  // FA5: stepBackward

    // Actions
    static let mic      = String.fontAwesomeIcon(name: .microphone)
    static let heart    = String.fontAwesomeIcon(name: .heart)
    static let export   = String.fontAwesomeIcon(name: .fileExport)
    static let search   = String.fontAwesomeIcon(name: .search)        // FA5: search (not magnifyingGlass)
    static let info     = String.fontAwesomeIcon(name: .infoCircle)    // FA5: infoCircle
    static let close    = String.fontAwesomeIcon(name: .times)         // FA5: times (not xmark)
    static let fire     = String.fontAwesomeIcon(name: .fire)
    static let trophy   = String.fontAwesomeIcon(name: .trophy)
    static let gear     = String.fontAwesomeIcon(name: .cog)           // FA5: cog (not gear)

    // Brands (render with .brands style)
    static let spotify  = String.fontAwesomeIcon(name: .spotify)
    static let youtube  = String.fontAwesomeIcon(name: .youtube)
    static let apple    = String.fontAwesomeIcon(name: .apple)

    /// Convenience: returns a Text view with the icon already sized and styled.
    static func icon(_ name: FontAwesome, size: CGFloat = 20, style: FontAwesomeStyle = .solid) -> Text {
        Text(String.fontAwesomeIcon(name: name))
            .font(.fontAwesome(ofSize: size, style: style))
    }
}
