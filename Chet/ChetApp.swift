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
    @State private var selectedID: WidgetUrlShabadID?
    @State private var isInFavorites: Bool = false
    @State private var shouldFocusSearch: Bool = false

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
                        selectedID = WidgetUrlShabadID(id: id)
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

struct WidgetUrlShabadID: Identifiable, Hashable, Equatable {
    let id: Int
}
