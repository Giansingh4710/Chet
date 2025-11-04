# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chet is a native iOS SwiftUI application for reading and searching Gurbani (Sikh scriptures). The app features search functionality, daily Hukamnama (edict), saved shabads with folder organization, and three WidgetKit widgets (RandomShabad, Hukamnama, and FavShabads).

## Build and Development Commands

### Opening the Project
```bash
open Chet.xcodeproj
```

### Building and Running
- Open `Chet.xcodeproj` in Xcode
- Select a simulator or connected iOS device
- Use Cmd+R to build and run
- Use Cmd+B to build only

### Testing
- Run tests with Cmd+U in Xcode
- Test targets: `ChetTests` and `ChetUITests`

## Architecture

### Data Flow and Persistence
- **SwiftData**: Primary data persistence framework using `@Model` classes
- **App Group**: `group.xyz.gians.Chet` shared container for widget-app data sharing
- **UserDefaults.appGroup**: Shared UserDefaults for widget configuration and random shabad data
- **ModelContainer.shared**: Singleton container defined in `Models.swift:292` with prepopulated default folders

### Core Data Models (Chet/Models.swift)
- **ShabadAPIResponse**: Main API response containing verses, metadata, and navigation
- **Verse**: Individual line with Gurmukhi text, translations (English/Punjabi/Hindi/Spanish), transliteration, and visraam (pause) markers
- **ShabadHistory**: SwiftData model tracking viewed shabads with `@Attribute(.unique)` on shabadID
- **SavedShabad**: Bookmarked shabads with folder relationship, tracks `indexOfSelectedLine` for widget display
- **Folder**: Hierarchical folder structure with parent-child relationships, supports drag-to-reorder with `sortIndex`

### API Integration (Chet/helpers/helper_funcs.swift)
- **Base URL**: `https://api.banidb.com/v2/`
- **Key Endpoints**:
  - `/random` - Random shabad (handles redirects to gurbaninow.com)
  - `/shabads/{id}` - Fetch complete shabad by ID
  - `/search/{query}?searchtype=0` - Search Gurbani
  - `/hukamnamas/{year}/{month}/{day}` - Daily Hukamnama
- All API calls use async/await pattern
- Responses decoded directly into model structs (no intermediate DTOs)

### Navigation Architecture (Chet/ContentView.swift)
- **TabView** with 3 tabs: Search (0), Saved (1), Settings (2)
- **Deep Linking**: Custom URL scheme `chet://`
  - `chet://shabadid/{id}` - Open shabad from RandomShabad/Hukamnama widgets
  - `chet://favshabadid/{id}` - Open saved shabad from FavShabads widget
  - `chet://search` - Focus search bar (triggered by widget magnifying glass button)
- Each tab has independent NavigationStack with path management
- Tapping active tab resets navigation path to root

### Widget Architecture
- **Three Widget Targets**: RandomShabadWidget, HukamnamaWidget, FavShabadsWidget
- **Shared Views**: `WidgetViews.swift` contains common rendering logic
- **Timeline Strategy**: RandomShabad refreshes at configurable intervals (default 3 hours), stores pre-fetched shabads in UserDefaults
- **Widget Families Supported**: systemSmall, systemMedium, systemLarge, accessoryInline, accessoryRectangular
- **Deep Links**: Widgets use `.widgetURL()` to open specific shabads in main app
- **Visraam Display**: Color-coded pause markers (orange for small pause 'v', green for big pause 'y')

### View Organization (Chet/Views/)
- **SearchView.swift**: Custom Punjabi keyboard (QWERTY and traditional layouts), auto-search after 2+ characters, history integration
- **ShabadView.swift**: Main shabad display with pinch-to-zoom gesture scale, swipe navigation between shabads, per-language translation settings, copy sheet with line selection
- **SavedShabadsView.swift**: Hierarchical folder navigation with OutlineGroup, bulk move operations in edit mode, import from iGurbani (.igb) and Gurbani Khoj (.gkhoj)
- **HukamnamaView.swift**: Date-based Hukamnama fetching with calendar picker
- **HistoryView.swift**: Recently viewed shabads sorted by dateViewed
- **SettingsView.swift**: App-wide settings (color scheme, font selection)

### Font System (Chet/helpers/helper_funcs.swift:213-228)
- **Unicode Mode**: Uses system font
- **Gurmukhi Fonts**: 9 custom fonts installed (AnmolLipi, GurbaniAkhar, NotoSans variants, etc.)
- **Font Resolution**: `resolveFont()` function with overloads for SwiftUI `Font` and UIKit `UIFont`
- **Font Selection**: Stored in `@AppStorage("fontType")` with default "Unicode"

### Settings and Configuration
- **@AppStorage Keys**: All settings prefixed with "settings." or specific feature names
- **Translation Sources**: Each language (English/Punjabi/Hindi/Spanish) has multiple source options (BDB, MS, SSK, etc.)
- **Text Scaling**: Independent scale factors for Gurbani, each translation language, and transliteration
- **Visraam Sources**: sttm, sttm2, igurbani (pause marker data sources)

## Important Patterns and Conventions

### SwiftData Relationships
- Use `@Relationship(deleteRule: .cascade)` for owned children
- Use `@Relationship(deleteRule: .nullify)` for references
- Always use `@Attribute(.unique)` for natural keys like shabadID
- Call `try? modelContext.save()` after mutations
- Use `#Predicate` for filtering in `@Query` and `FetchDescriptor`

### Widget Data Synchronization
- Call `WidgetCenter.shared.reloadTimelines(ofKind:)` when widget-related data changes
- Use `WidgetCenter.shared.reloadAllTimelines()` for broad updates
- Store widget data in `UserDefaults.appGroup` not standard UserDefaults
- Always check `startAccessingSecurityScopedResource()` when importing files

### Gesture Handling in ShabadView
- MagnificationGesture updates gestureScale (temporary), then applies to all text scale settings on end
- DragGesture for horizontal swipe navigation between shabads (disabled via setting)
- Tap on Gurbani line toggles larivaar (connected text) mode
- LongPress on line opens copy sheet with that line preselected

### Search Implementation
- First-letter search supported via `getFirstLetters()` function (removes matras/diacritics)
- Custom Punjabi keyboard intercepts system keyboard with empty UIView inputView
- Search triggers automatically on text change if length > 2
- Results show highlighted searched line when navigating to shabad

### Import/Export Support
- iGurbani format (.igb): JSON with nested folder structure
- Gurbani Khoj format (.gkhoj): PropertyList (plist) format
- Import creates new root folder with app name prefix
- Shows live import progress counter using ZStack overlay
- Import functions use async callbacks for progress updates

## Development Notes

- **iOS Version**: Targets iOS 17.0+ (uses `#available` checks in some places)
- **Xcode Version**: Developed with Xcode 16.0
- **Idle Timer**: Disabled when viewing shabads to prevent screen sleep (re-enabled onDisappear)
- **Color Scheme**: Supports light/dark mode with per-theme visraam colors and background colors
- **Git Hooks**: None configured
- **Dependencies**: No external package dependencies - uses only Apple frameworks

## Key File Locations

- App entry point: `Chet/ChetApp.swift`
- Data models: `Chet/Models.swift`
- API functions: `Chet/helpers/helper_funcs.swift`
- Shared widget views: `WidgetViews.swift` (root directory)
- App group ID: `group.xyz.gians.Chet` (also in entitlements files)
