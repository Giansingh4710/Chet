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
    @State private var shouldFocusSearch: Bool = false // Add this
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                selectedID: $selectedID,
                shouldFocusSearch: $shouldFocusSearch // Pass binding
            )
            .preferredColorScheme(selectedScheme)
            .onOpenURL { url in
                if url.scheme == "chet" {
                    if url.host == "shabadid",
                       let idstr = url.pathComponents.dropFirst().first,
                       let id = Int(idstr)
                    {
                        selectedID = WidgetUrlShabadID(id: id)
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

struct WidgetUrlShabadID: Identifiable {
    let id: Int
}

