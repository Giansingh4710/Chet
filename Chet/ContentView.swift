//
//  ContentView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var selectedID: WidgetUrlShabadID?

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @State private var searchNavPath = NavigationPath()
    @State private var favoritesNavPath = NavigationPath()
    @State private var historyNavPath = NavigationPath()
    @State private var settingsNavPath = NavigationPath()

    @State private var editMode: EditMode = .inactive

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $searchNavPath) {
                SearchView()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if oldValue == newValue && newValue == 0 {
                    searchNavPath = NavigationPath()
                }
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .tag(0)

            // Other tabs remain the same
            NavigationStack(path: $favoritesNavPath) {
                SavedShabadsView()
                    .environment(\.editMode, $editMode) // inject editMode here
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if oldValue == newValue && newValue == 1 {
                    favoritesNavPath = NavigationPath()
                }
            }
            .tabItem {
                Image(systemName: "bookmark")
                Text("Saved")
            }
            .tag(1)

            NavigationStack(path: $historyNavPath) {
                ShabadHistoryView()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if oldValue == newValue && newValue == 2 {
                    historyNavPath = NavigationPath()
                }
            }
            .tabItem {
                Image(systemName: "clock")
                Text("History")
            }
            .tag(2)

            NavigationStack(path: $settingsNavPath) {
                SettingsView()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if oldValue == newValue && newValue == 3 {
                    settingsNavPath = NavigationPath()
                }
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .sheet(item: $selectedID) { id_obj in
            ShabadViewFromWidgetURL(id: id_obj.id)
        }
    }
}

struct ShabadViewFromWidgetURL: View {
    let id: String
    @State private var sbd: ShabadAPIResponse?

    var body: some View {
        Group {
            if let sbd {
                ShabadViewDisplayWrapper(sbdRes: sbd, indexOfLine: 0)
            } else {
                ProgressView("Loading…")
                    .task {
                        if sbd == nil {
                            do {
                                sbd = try await fetchShabadResponse(from: id)
                            } catch {
                                print(error)
                            }
                        }
                    }
            }
        }
    }
}

// #Preview {
//     ContentView()
// }
