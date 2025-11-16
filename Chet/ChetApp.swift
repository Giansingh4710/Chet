//
//  ChetApp.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftData
import SwiftUI

@main
struct ChetApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @State private var selectedID: IdentifiableInt?
    @State private var isInFavorites: Bool = false
    @State private var shouldFocusSearch: Bool = false

    init() {
        // Sync all widget-relevant settings to app group on launch
        syncSettingsToAppGroup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                selectedID: $selectedID,
                isInFavorites: $isInFavorites,
                shouldFocusSearch: $shouldFocusSearch // Pass binding
            )
            .preferredColorScheme(selectedScheme)
            .onOpenURL { url in
                if url.scheme == "chet" {
                    if url.host == "shabadid" || url.host == "favshabadid",
                       let idstr = url.pathComponents.dropFirst().first,
                       let id = Int(idstr)
                    {
                        selectedID = IdentifiableInt(id: id)
                        isInFavorites = url.host == "favshabadid"
                    } else if url.host == "search" {
                        shouldFocusSearch = true // Trigger search focus
                    }
                }
            }
        }
        .modelContainer(ModelContainer.shared)
    }

    private var selectedScheme: ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

struct IdentifiableInt: Identifiable, Hashable, Equatable {
    let id: Int
}

// Helper function to sync all widget-relevant settings to app group
func syncSettingsToAppGroup() {
    let standard = UserDefaults.standard
    let appGroup = UserDefaults.appGroup

    // Sync font
    if let fontType = standard.string(forKey: "fontType") {
        appGroup.set(fontType, forKey: "fontType")
    }

    // Sync visraam
    if let visraamSource = standard.string(forKey: "settings.visraamSource") {
        appGroup.set(visraamSource, forKey: "settings.visraamSource")
    }

    // Sync larivaar settings
    appGroup.set(standard.bool(forKey: "settings.larivaarOn"), forKey: "settings.larivaarOn")
    appGroup.set(standard.bool(forKey: "settings.larivaarAssist"), forKey: "settings.larivaarAssist")

    // Sync translation sources
    if let englishSource = standard.string(forKey: "settings.englishSource") {
        appGroup.set(englishSource, forKey: "settings.englishSource")
    }
    if let punjabiSource = standard.string(forKey: "settings.punjabiSource") {
        appGroup.set(punjabiSource, forKey: "settings.punjabiSource")
    }
    if let hindiSource = standard.string(forKey: "settings.hindiSource") {
        appGroup.set(hindiSource, forKey: "settings.hindiSource")
    }
    if let spanishSource = standard.string(forKey: "settings.spanishSource") {
        appGroup.set(spanishSource, forKey: "settings.spanishSource")
    }

    // Sync transliteration
    if let transliterationSource = standard.string(forKey: "settings.transliterationSource") {
        appGroup.set(transliterationSource, forKey: "settings.transliterationSource")
    }
}
