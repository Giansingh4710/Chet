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
    @State private var selectedID: WidgetUrlShabadID? // need the type to be "Identifiable" for the .sheet to work

    var body: some Scene {
        WindowGroup {
            ContentView(selectedID: $selectedID)
                .preferredColorScheme(selectedScheme)
                .onOpenURL { url in
                    if url.scheme == "chet",
                       url.host == "shabadid",
                       let id = url.pathComponents.dropFirst().first
                    {
                        selectedID = WidgetUrlShabadID(id: id)
                    }
                }
        }
        .modelContainer(ModelContainer.shared)
    }

    private var selectedScheme: ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }
}

struct WidgetUrlShabadID: Identifiable {
    let id: String
}
