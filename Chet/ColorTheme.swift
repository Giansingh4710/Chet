//
//  ColorTheme.swift
//  Chet
//
//  Centralized color theme for the entire app
//

import SwiftUI

struct AppColors {
    // MARK: - Visraam Colors (Pause Markers)

    /// Small pause marker color (v)
    static func visraamSmall(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.5, blue: 0.3)   // Dark mode: Lighter orange
            : Color(red: 0.9, green: 0.2, blue: 0.0)   // Light mode: Deep orange-red
    }

    /// Big pause marker color (y)
    static func visraamBig(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.3, green: 1.0, blue: 0.3)   // Dark mode: Bright green
            : Color(red: 0.0, green: 0.7, blue: 0.0)   // Light mode: Deep green
    }

    // MARK: - Larivaar Assist Colors (Alternating word colors)

    /// Even word color for larivaar assist
    static func larivaarAssistEven(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.75, green: 0.85, blue: 1.0)  // Dark mode: Light blue
            : Color(red: 0.05, green: 0.25, blue: 0.55) // Light mode: Deep blue
    }

    /// Odd word color for larivaar assist
    static func larivaarAssistOdd(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.8, blue: 0.65)   // Dark mode: Light orange
            : Color(red: 0.55, green: 0.35, blue: 0.05) // Light mode: Deep orange-brown
    }

    // MARK: - Helper Methods

    /// Get visraam color based on type
    static func visraamColor(type: String, for colorScheme: ColorScheme) -> Color {
        switch type {
        case "v":
            return visraamSmall(for: colorScheme)
        case "y":
            return visraamBig(for: colorScheme)
        default:
            return .primary
        }
    }

    /// Get larivaar assist color based on word index
    static func larivaarAssistColor(index: Int, for colorScheme: ColorScheme) -> Color {
        let isEven = index % 2 == 0
        return isEven
            ? larivaarAssistEven(for: colorScheme)
            : larivaarAssistOdd(for: colorScheme)
    }

    // MARK: - Translation and Transliteration Colors

    /// Transliteration text color
    static func transliterationColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.75, green: 0.75, blue: 0.75)  // Dark mode: Light gray
            : Color(red: 0.5, green: 0.5, blue: 0.5)     // Light mode: Medium gray
    }

    /// English translation text color
    static func englishTranslationColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.7, green: 0.85, blue: 1.0)    // Dark mode: Light blue
            : Color(red: 0.2, green: 0.4, blue: 0.7)     // Light mode: Deep blue
    }

    /// Punjabi translation text color
    static func punjabiTranslationColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.85, blue: 0.6)    // Dark mode: Light peach
            : Color(red: 0.65, green: 0.45, blue: 0.2)   // Light mode: Deep brown
    }

    /// Hindi translation text color
    static func hindiTranslationColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.75, blue: 0.85)   // Dark mode: Light pink
            : Color(red: 0.6, green: 0.3, blue: 0.5)     // Light mode: Deep mauve
    }

    /// Spanish translation text color
    static func spanishTranslationColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.85, green: 0.95, blue: 0.75)  // Dark mode: Light yellow-green
            : Color(red: 0.4, green: 0.6, blue: 0.3)     // Light mode: Deep olive green
    }
}
