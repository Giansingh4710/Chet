//
//  ContentView.swift
//  Chet
//
//  Created by gian singh on 8/29/25.
//

import _SwiftData_SwiftUI
import SwiftUI
import WidgetKit

struct ContentView: View {
    @Binding var selectedID: IdentifiableInt?
    @Binding var isInFavorites: Bool
    @Binding var shouldFocusSearch: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var searchNavPath = NavigationPath()
    @State private var baniNavPath = NavigationPath()
    @State private var favoritesNavPath = NavigationPath()
    @State private var settingsNavPath = NavigationPath()

    @State private var triggerSearchFocus = false // Internal trigger after nav is cleared
    @State private var editMode: EditMode = .inactive

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $searchNavPath) {
                SearchView(shouldFocusSearchBar: $triggerSearchFocus)
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .tag(0)

            NavigationStack(path: $favoritesNavPath) {
                SavedShabadsView()
                    .environment(\.editMode, $editMode) // inject editMode here
                    .navigationDestination(item: $selectedID) { id_obj in
                        ShabadViewFromWidgetURL(id: id_obj.id, isInFavorites: isInFavorites)
                    }
            }
            .tabItem {
                Image(systemName: "bookmark")
                Text("Saved")
            }
            .tag(1)

            NavigationStack(path: $baniNavPath) {
                BaniListView()
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("Banis")
            }
            .tag(2)

            NavigationStack(path: $settingsNavPath) {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
        .onChange(of: selectedID) { id_obj in
            if let id_obj = id_obj {
                selectedTab = 1
                favoritesNavPath = NavigationPath() // reset stack
                // favoritesNavPath.append(id_obj) // append data, not view
            }
        }
        .onChange(of: shouldFocusSearch) { _, newValue in
            if newValue {
                // Step 1: Clear all navigation immediately
                searchNavPath = NavigationPath()
                baniNavPath = NavigationPath()
                favoritesNavPath = NavigationPath()
                settingsNavPath = NavigationPath()
                selectedID = nil

                // Step 2: Switch to Search tab
                selectedTab = 0

                // Step 3: Wait for navigation to clear, then trigger search focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    triggerSearchFocus = true
                }

                // Step 4: Reset flags after SearchView has had time to focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    shouldFocusSearch = false
                    triggerSearchFocus = false
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
    }
}

struct ShabadViewFromWidgetURL: View {
    let id: Int
    let isInFavorites: Bool
    @State private var sbd: ShabadAPIResponse?
    @State private var svdSbd: SavedShabad?

    @Query(
        filter: #Predicate<Folder> { $0.parentFolder == nil },
        sort: \.sortIndex
    ) private var rootFolders: [Folder]

    var body: some View {
        Group {
            if let sbd {
                ShabadViewDisplayWrapper(sbdRes: sbd, indexOfLine: 0)
            } else if let svdSbd {
                ShabadViewDisplayWrapper(sbdRes: svdSbd.sbdRes, indexOfLine: svdSbd.indexOfSelectedLine, onIndexChange: { newIndex in
                    svdSbd.indexOfSelectedLine = newIndex
                    WidgetCenter.shared.reloadTimelines(ofKind: "xyz.gians.Chet.FavShabadsWidget")
                })
            } else {
                ProgressView("Loading…")
            }
        }
        .onAppear {
            if isInFavorites {
                Task {
                    do {
                        try await loadFromFavorites()
                    } catch {
                        print(error)
                    }
                }
            } else {
                Task {
                    do {
                        try await loadFromAPI()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }

    func loadFromFavorites() async {
        guard let favoritesFolder = rootFolders.first(where: { $0.name == "Favorites" }) else {
            return
        }

        if let favoriteShabad = favoritesFolder.savedShabads.first(where: { $0.sbdRes.shabadInfo.shabadId == id }) {
            svdSbd = favoriteShabad
        } else {
            print("Shabad with id \(id) not found in Favorites. Something VERY WRONG")
        }
    }

    func loadFromAPI() async {
        do {
            sbd = try await fetchShabadResponse(from: id)
        } catch {
            print(error)
        }
    }
}

// #Preview {
//     ContentView()
// }
