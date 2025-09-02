//
//  ChetApp.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftUI
import SwiftData

@main
struct ChetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // .preferredColorScheme(.none) // Allow system to choose light/dark mode
                .preferredColorScheme(.dark) // Allow system to choose light/dark mode
        }
        .modelContainer(ModelContainer.shared)
        // .modelContainer(for: [FavoriteShabad.self, ShabadHistory.self], isAutosaveEnabled: true)
    }
}
