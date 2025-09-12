//
//  ContentView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @State private var searchNavPath = NavigationPath()
    @State private var favoritesNavPath = NavigationPath()
    @State private var historyNavPath = NavigationPath()

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
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}
