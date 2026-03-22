// Icons.swift
// Single source of truth for all FontAwesome icons used in MeloMo.
// Why: prevents magic strings scattered through views — one rename fixes everything.
// FA enum cases are the only safe lookup; rawValue is a Unicode char, not a CSS name.
import FontAwesome
import SwiftUI

enum Icons {
    // Tabs
    static let vibes    = String.fontAwesomeIcon(name: .music)
    static let library  = String.fontAwesomeIcon(name: .layerGroup)
    static let stats    = String.fontAwesomeIcon(name: .chartBar)
    static let profile  = String.fontAwesomeIcon(name: .circleUser)

    // Playback
    static let play     = String.fontAwesomeIcon(name: .circlePlay)
    static let pause    = String.fontAwesomeIcon(name: .circlePause)
    static let skipNext = String.fontAwesomeIcon(name: .forwardStep)
    static let skipPrev = String.fontAwesomeIcon(name: .backwardStep)

    // Actions
    static let mic      = String.fontAwesomeIcon(name: .microphone)
    static let heart    = String.fontAwesomeIcon(name: .heart)
    static let export   = String.fontAwesomeIcon(name: .fileExport)
    static let search   = String.fontAwesomeIcon(name: .magnifyingGlass)
    static let info     = String.fontAwesomeIcon(name: .circleInfo)
    static let close    = String.fontAwesomeIcon(name: .xmark)
    static let fire     = String.fontAwesomeIcon(name: .fire)
    static let trophy   = String.fontAwesomeIcon(name: .trophy)
    static let gear     = String.fontAwesomeIcon(name: .gear)

    // Brands (need .brands style when rendering)
    static let spotify  = String.fontAwesomeIcon(name: .spotify)
    static let youtube  = String.fontAwesomeIcon(name: .youtube)
    static let apple    = String.fontAwesomeIcon(name: .apple)

    /// Returns a SwiftUI Text view with the icon at a given size.
    static func icon(_ name: FontAwesome, size: CGFloat = 20, style: FontAwesomeStyle = .solid) -> Text {
        Text(String.fontAwesomeIcon(name: name))
            .font(Font.fontAwesome(ofSize: size, style: style))
    }
}
