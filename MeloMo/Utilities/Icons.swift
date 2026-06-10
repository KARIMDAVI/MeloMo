// Icons.swift
// Single source of truth for all FontAwesome icons used in MeloMo.
// Why: prevents magic strings scattered through views — one rename fixes everything.
// Note: thii/FontAwesome.swift uses FA5 naming (e.g. .userCircle, not .circleUser).
import SwiftUI
import FontAwesome
import UIKit

struct Icons {
    // Tab Bar
    static let vibes = FontAwesome.Icon.music
    static let library = FontAwesome.Icon.book
    static let stats = FontAwesome.Icon.chartSimple
    static let settings = FontAwesome.Icon.gear
    
    // Playback Controls
    static let play = FontAwesome.Icon.play
    static let pause = FontAwesome.Icon.pause
    static let next = FontAwesome.Icon.forward
    static let previous = FontAwesome.Icon.backward
    
    // General UI
    static let search = FontAwesome.Icon.magnifyingGlass
    static let close = FontAwesome.Icon.xmark
    static let heart = FontAwesome.Icon.heart
    static let heartSolid = FontAwesome.Icon.solidHeart
    static let share = FontAwesome.Icon.share
    static let mic = FontAwesome.Icon.microphone
    static let info = FontAwesome.Icon.infoCircle
    static let user = FontAwesome.Icon.user
    static let chevronRight = FontAwesome.Icon.chevronRight
    
    // Brands
    static let spotify = FontAwesome.Icon.spotify
    static let apple = FontAwesome.Icon.apple
    static let youtube = FontAwesome.Icon.youtube
}

private enum FASafe {
    static func familyName(for style: FontAwesome.Style) -> String {
        switch style {
        case .brands:
            return "Font Awesome 5 Brands"
        default:
            return "Font Awesome 5 Free"
        }
    }

    static func isFontAvailable(for style: FontAwesome.Style) -> Bool {
        !UIFont.fontNames(forFamilyName: familyName(for: style)).isEmpty
    }
}

extension Text {
    static func fa(_ icon: FontAwesome.Icon, style: FontAwesome.Style = .solid, size: CGFloat = 20) -> Text {
        Text(icon.rawValue).font(.fa(style, size: size))
    }

    static func faSafe(_ icon: FontAwesome.Icon, style: FontAwesome.Style = .solid, size: CGFloat = 20, fallback: String = "?") -> Text {
        guard FASafe.isFontAvailable(for: style) else {
            return Text(fallback).font(.system(size: size, weight: .semibold))
        }
        return Text(icon.rawValue).font(.fa(style, size: size))
    }
}

extension Image {
    static func fa(_ icon: FontAwesome.Icon, style: FontAwesome.Style = .solid) -> Image {
        Image(uiImage: .fa(icon, style: style))
    }

    static func faSafe(_ icon: FontAwesome.Icon, style: FontAwesome.Style = .solid, fallbackSystemName: String = "questionmark.circle") -> Image {
        guard FASafe.isFontAvailable(for: style) else {
            return Image(systemName: fallbackSystemName)
        }
        return Image(uiImage: .fa(icon, style: style))
    }
}
