//
//  ContentView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            FavoriteShabadsView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
            
            ShabadHistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}
